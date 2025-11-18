package com.example.api.util;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

/**
 * シーズン計算ユーティリティクラス
 * Season 0は開始日から3ヶ月（90日）、その後3ヶ月ごとにシーズン番号がインクリメントされます
 */
@Component
public class SeasonCalculator {

    /**
     * シーズン0の開始日（application.propertiesで設定可能）
     * デフォルト: 2025-01-01
     */
    @Value("${season.start-date:2025-01-01}")
    private String seasonStartDateString;

    /** シーズン期間（日数） */
    private static final long SEASON_DURATION_DAYS = 90;

    /**
     * 現在のシーズン番号を取得
     * @return 現在のシーズン番号（0, 1, 2, ...）
     */
    public Integer getCurrentSeason() {
        return getCurrentSeason(LocalDate.now());
    }

    /**
     * 指定日付のシーズン番号を取得
     * @param date 対象日付
     * @return シーズン番号（0, 1, 2, ...）
     */
    public Integer getCurrentSeason(LocalDate date) {
        LocalDate seasonStartDate = LocalDate.parse(seasonStartDateString);

        // 開始日より前の日付の場合はSeason 0を返す
        if (date.isBefore(seasonStartDate)) {
            return 0;
        }

        // 開始日からの経過日数を計算
        long daysSinceStart = ChronoUnit.DAYS.between(seasonStartDate, date);

        // シーズン番号を計算（0から始まる）
        int season = (int) (daysSinceStart / SEASON_DURATION_DAYS);

        return season;
    }

    /**
     * 指定シーズンの開始日を取得
     * @param season シーズン番号
     * @return シーズン開始日
     */
    public LocalDate getSeasonStartDate(Integer season) {
        LocalDate seasonStartDate = LocalDate.parse(seasonStartDateString);
        return seasonStartDate.plusDays(season * SEASON_DURATION_DAYS);
    }

    /**
     * 指定シーズンの終了日を取得
     * @param season シーズン番号
     * @return シーズン終了日
     */
    public LocalDate getSeasonEndDate(Integer season) {
        LocalDate seasonStartDate = LocalDate.parse(seasonStartDateString);
        return seasonStartDate.plusDays((season + 1) * SEASON_DURATION_DAYS - 1);
    }

    /**
     * 現在のシーズンの残り日数を取得
     * @return 残り日数
     */
    public long getDaysRemainingInCurrentSeason() {
        Integer currentSeason = getCurrentSeason();
        LocalDate endDate = getSeasonEndDate(currentSeason);
        return ChronoUnit.DAYS.between(LocalDate.now(), endDate);
    }

    /**
     * シーズン開始日の文字列を取得（主にテスト用）
     * @return シーズン開始日（YYYY-MM-DD形式）
     */
    public String getSeasonStartDateString() {
        return seasonStartDateString;
    }
}
