package com.example.api.dto;

import java.time.LocalDate;
import java.util.List;

public class WeeklyRankingResponse {
    private LocalDate weekStart;
    private LocalDate weekEnd;
    private List<RankingEntryDto> entries;
    private int myRank;

    public LocalDate getWeekStart() { return weekStart; }
    public void setWeekStart(LocalDate weekStart) { this.weekStart = weekStart; }
    public LocalDate getWeekEnd() { return weekEnd; }
    public void setWeekEnd(LocalDate weekEnd) { this.weekEnd = weekEnd; }
    public List<RankingEntryDto> getEntries() { return entries; }
    public void setEntries(List<RankingEntryDto> entries) { this.entries = entries; }
    public int getMyRank() { return myRank; }
    public void setMyRank(int myRank) { this.myRank = myRank; }
}