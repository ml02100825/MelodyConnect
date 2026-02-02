package com.example.api.dto.admin;

import jakarta.validation.constraints.NotEmpty;
import java.util.List;

/**
 * 一括ユーザー操作リクエストDTO
 */
public class BulkUserActionRequest {

    @NotEmpty(message = "ユーザーIDリストは必須です")
    private List<Long> userIds;

    public List<Long> getUserIds() { return userIds; }
    public void setUserIds(List<Long> userIds) { this.userIds = userIds; }
}
