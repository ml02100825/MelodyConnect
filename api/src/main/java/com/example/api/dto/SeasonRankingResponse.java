package com.example.api.dto;

import java.time.LocalDateTime;
import java.util.List;

import com.example.api.entity.WeeklyLessons;

public class SeasonRankingResponse {
    private String season;
    private boolean isActive;
    private LocalDateTime lastUpdated;
    private List<RankingEntryDto> entries;
    private int myRank;

    public String getSeason() { return season; }
    public void setSeason(String season) { this.season = season; }
    public boolean isActive() { return isActive; }
    public void setActive(boolean active) { isActive = active; }
    public LocalDateTime getLastUpdated() { return lastUpdated; }
    public void setLastUpdated(LocalDateTime lastUpdated) { this.lastUpdated = lastUpdated; }
    public List<RankingEntryDto> getEntries() { return entries; }
    public void setEntries(List<RankingEntryDto> entries) { this.entries = entries; }
    public int getMyRank() { return myRank; }
    public void setMyRank(int myRank) { this.myRank = myRank; }
}