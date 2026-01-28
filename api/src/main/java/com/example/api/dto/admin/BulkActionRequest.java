package com.example.api.dto.admin;

import jakarta.validation.constraints.NotEmpty;
import java.util.List;

/**
 * 汎用一括操作リクエストDTO
 */
public class BulkActionRequest {

    @NotEmpty(message = "IDリストは必須です")
    private List<Integer> ids;

    public List<Integer> getIds() { return ids; }
    public void setIds(List<Integer> ids) { this.ids = ids; }
}
