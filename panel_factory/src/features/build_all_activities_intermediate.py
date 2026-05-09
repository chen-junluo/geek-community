# Artifact:  intermediate/all_activities
# 输入:      data/raw/cmn_base.csv, data/raw/votes_content.csv, data/raw/object_id.csv
# Grain:     activity-level (userURL × date × activity_type)
# Merge keys: userURL, date
# 输出:      data/features/all_activities.csv
#
# 逻辑：合并 asks, answers, comments 到统一 timeline
#       计算 commentAsker, commentResponder, commentOthers
#       添加 accepted_thisQue, comment_thisCmn 等字段
#
# 从 Archive notebook cells 26-33 提取

import os

import pandas as pd
import numpy as np
from tqdm import tqdm

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["features"]["all_activities"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def _load_raw_data(raw_dir: str):
    """Load raw data files."""
    cmn_base = pd.read_csv(os.path.join(raw_dir, "cmn_base.csv"))
    cmn_base["date"] = pd.to_datetime(cmn_base["date"]).dt.tz_localize(None)

    # Check if votes_content exists
    votes_path = os.path.join(raw_dir, "votes_content.csv")
    if not os.path.exists(votes_path):
        print(f"  ⚠ Warning: {votes_path} not found, skipping comment data")
        votes_content = None
    else:
        votes_content = pd.read_csv(votes_path)

    # Check if object_id exists
    object_id_path = os.path.join(raw_dir, "object_id.csv")
    if not os.path.exists(object_id_path):
        print(f"  ⚠ Warning: {object_id_path} not found, skipping comment data")
        object_id = None
    else:
        object_id = pd.read_csv(object_id_path, encoding="utf-8-sig")
        if "title" in object_id.columns:
            object_id = object_id.drop(columns=["title"])

    return cmn_base, votes_content, object_id


def _build_cmns_copy(cmn_base):
    """Build cmns_copy from cmn_base (asks + answers)."""
    cmns_copy = cmn_base[
        ["date", "userURL", "netlikeNum", "questionURL", "cmnID", "ask", "answer", "accept"]
    ].copy()

    cmns_copy["comment"] = 0
    cmns_copy["commentAsker"] = 0
    cmns_copy["commentResponder"] = 0
    cmns_copy["commentOthers"] = 0

    return cmns_copy


def _build_votes_copy(cmn_base, votes_content, object_id):
    """Build votes_copy from votes_content (comments)."""
    if votes_content is None or object_id is None:
        return pd.DataFrame()

    # Prepare cmn_base_object for lookup
    cmn_base["date"] = pd.to_datetime(cmn_base["date"])
    cmn_base["object_id"] = cmn_base["object_id"].astype(str) if "object_id" in cmn_base.columns else None

    if cmn_base["object_id"].isna().all():
        # Merge object_id
        cmn_base_object = cmn_base.merge(object_id, on=["questionURL", "cmnID"], how="left")
    else:
        cmn_base_object = cmn_base.copy()

    cmn_base_object["object_id"] = cmn_base_object["object_id"].astype(str)
    cmn_base_object = cmn_base_object[
        ["questionURL", "cmnID", "userName", "userURL", "object_id", "date", "accept"]
    ]

    # Build votes_copy
    votes_copy = votes_content[["date", "user_url", "votes", "object_id"]].copy()
    votes_copy = votes_copy.rename(columns={"user_url": "userURL", "votes": "netlikeNum"})
    votes_copy["object_id"] = votes_copy["object_id"].astype(str)

    # Merge to get questionURL and cmnID
    votes_copy = votes_copy.merge(
        cmn_base_object[["questionURL", "cmnID", "object_id"]],
        on="object_id",
        how="left"
    )

    # Standardize userURL
    votes_copy["userURL"] = votes_copy["userURL"].apply(
        lambda x: f"https://segmentfault.com{x}" if pd.notna(x) else ""
    )

    # Initialize activity columns
    votes_copy[["ask", "answer", "accept"]] = 0
    votes_copy["comment"] = 1

    # Calculate commentAsker, commentResponder, commentOthers
    def process_group(group):
        object_id = group.name
        currentURL = group["questionURL"].iloc[0]
        cmnID = group["cmnID"].iloc[0]

        current_question = cmn_base_object[cmn_base_object["questionURL"] == currentURL]

        # Get asker URL
        asker_rows = current_question[current_question["cmnID"] == 0]
        if len(asker_rows) == 0:
            askerURL = ""
        else:
            askerURL = asker_rows.iloc[0]["userURL"]

        # Get responder URL
        responder_rows = current_question[current_question["object_id"] == object_id]
        if len(responder_rows) == 0:
            responderURL = ""
        else:
            responderURL = responder_rows.iloc[0]["userURL"]

        # Classify comments
        group["commentAsker"] = group["userURL"].apply(lambda x: 1 if x == askerURL else 0)
        group["commentResponder"] = group["userURL"].apply(
            lambda x: 1 if x == responderURL and askerURL != responderURL else 0
        )
        group["commentOthers"] = group["userURL"].apply(
            lambda x: 1 if x != askerURL and x != responderURL else 0
        )

        return group

    tqdm.pandas(desc="Processing comment groups")
    votes_copy = votes_copy.groupby("object_id").progress_apply(process_group).reset_index(drop=True)

    # Convert date
    votes_copy["date"] = pd.to_datetime(votes_copy["date"]).dt.tz_localize(None)

    # Drop object_id
    votes_copy = votes_copy.drop(columns=["object_id"])

    return votes_copy


def _merge_and_enrich(cmns_copy, votes_copy):
    """Merge cmns_copy and votes_copy, then enrich with aggregated fields."""
    # Concatenate
    all_activities = pd.concat([cmns_copy, votes_copy], ignore_index=True)

    # Sort by date
    all_activities = all_activities.sort_values(by="date").reset_index(drop=True)

    # Drop duplicates
    all_activities = all_activities.drop_duplicates(keep="first")

    # Rename accept to accepted
    all_activities = all_activities.rename(columns={"accept": "accepted"})

    # Calculate accepted_thisQue
    all_activities["accepted_thisQue"] = all_activities.groupby("questionURL")["accepted"].transform("sum")
    all_activities["accepted_thisQue"] = all_activities["accepted_thisQue"].apply(lambda x: 1 if x >= 1 else 0)

    # Calculate comment_thisCmn
    all_activities["comment_thisCmn"] = all_activities.groupby(["questionURL", "cmnID"])["comment"].transform("sum")
    all_activities["commentAsker_thisCmn"] = all_activities.groupby(["questionURL", "cmnID"])["commentAsker"].transform("sum")
    all_activities["commentResponder_thisCmn"] = all_activities.groupby(["questionURL", "cmnID"])["commentResponder"].transform("sum")
    all_activities["commentOthers_thisCmn"] = all_activities.groupby(["questionURL", "cmnID"])["commentOthers"].transform("sum")

    # Update accept column
    def update_accept(row):
        if row["cmnID"] == 0 and row["ask"] == 1:
            return row["accepted_thisQue"]
        else:
            return 0

    tqdm.pandas(desc="Updating accept column")
    all_activities["accept"] = all_activities.progress_apply(update_accept, axis=1)

    return all_activities


def build(raw_dir: str = ARTIFACT_PATHS["raw"]) -> pd.DataFrame:
    print("Loading raw data...")
    cmn_base, votes_content, object_id = _load_raw_data(raw_dir)

    print("Building cmns_copy (asks + answers)...")
    cmns_copy = _build_cmns_copy(cmn_base)
    print(f"  cmns_copy shape: {cmns_copy.shape}")

    print("Building votes_copy (comments)...")
    votes_copy = _build_votes_copy(cmn_base, votes_content, object_id)
    if len(votes_copy) > 0:
        print(f"  votes_copy shape: {votes_copy.shape}")
    else:
        print(f"  votes_copy: empty (no comment data)")

    print("Merging and enriching...")
    all_activities = _merge_and_enrich(cmns_copy, votes_copy)

    all_activities.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"all_activities 已保存: {OUTPUT_CSV}  shape={all_activities.shape}")
    print(f"  - asks: {all_activities['ask'].sum()}")
    print(f"  - answers: {all_activities['answer'].sum()}")
    print(f"  - comments: {all_activities['comment'].sum()}")
    return all_activities


if __name__ == "__main__":
    build()
