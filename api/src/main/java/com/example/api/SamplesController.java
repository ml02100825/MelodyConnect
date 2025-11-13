package com.example.api;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
public class SamplesController {

  private final JdbcTemplate jdbc;

  public SamplesController(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @GetMapping("/api/samples")
  public List<Map<String, Object>> getSamples() {
    return jdbc.queryForList("SELECT id, message, created_at FROM samples ORDER BY id");
  }
}
