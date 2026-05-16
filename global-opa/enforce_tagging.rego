package enforce_specified_tags

# delete アクションを含むリソースかどうかを判定する helper ルール
is_delete(resource_change) {
    resource_change.change.actions[_] == "delete"
}

deny[msg] {
    resource_change := input.resource_changes[_]
    not is_delete(resource_change)
    tags := resource_change.change.after.tags
    tags != null
    not tags["ManagedBy"]
    msg := sprintf("%s: ManagedBy タグが未設定", [resource_change.address])
}

allow {
    count(deny) == 0
}
