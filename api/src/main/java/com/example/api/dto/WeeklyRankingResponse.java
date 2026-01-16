package com.example.api.dto;

import java.time.LocalDate;

public class WeeklyRankingResponse {
    private LocalDate weekStart;
    private LocalDate weekEnd;
    private int myRank;

    public LocalDate getWeekStart() { return weekStart; }
    public void setWeekStart(LocalDate weekStart) { this.weekStart = weekStart; }
    public LocalDate getWeekEnd() { return weekEnd; }
    public void setWeekEnd(LocalDate weekEnd) { this.weekEnd = weekEnd; }
    public int getMyRank() { return myRank; }
    public void setMyRank(int myRank) { this.myRank = myRank; }
}