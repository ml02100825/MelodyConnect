package com.example.api.dto.admin;

import jakarta.validation.constraints.NotEmpty;
import java.util.List;

/**
 * Long型ID用一括操作リクエストDTO
 */
public class BulkLongActionRequest {

    @NotEmpty(message = "IDリストは必須です")
    private List<Long> ids;

    public List<Long> getIds() { return ids; }
    public void setIds(List<Long> ids) { this.ids = ids; }
}
