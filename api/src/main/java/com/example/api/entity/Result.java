package com.example.api.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Map;

@Entity
@Table(
    name = "result",
    indexes = {
        @Index(name = "idx_result_player", columnList = "player_id"),
        @Index(name = "idx_result_enemy", columnList = "enemy_id"),
        @Index(name = "idx_result_match_uuid", columnList = "match_uuid")
    }
)
public class Result {

    public enum MatchType { rank, room }
    public enum OutcomeReason { normal, surrender, timeout, disconnect }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "result_id", nullable = false)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "player_id", nullable = false)
    private User player;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "enemy_id", nullable = false)
    private User enemy;

    /** true=勝ち / false=負け */
    @Column(name = "result", nullable = false)
    private Boolean result;

    @Column(name = "updown_rate", nullable = false)
    private Integer updownRate;

    /** 対戦終了時のレート */
    @Column(name = "rate_after_match")
    private Integer rateAfterMatch;

    @Column(name = "use_language", length = 30)
    private String useLanguage;

    /** 使用した問題(JSON) */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "use_question", columnDefinition = "json")
    private Map<String, Object> useQuestion;

    /** 結果詳細(JSON) */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "result_detail", columnDefinition = "json")
    private Map<String, Object> resultDetail;

    /** BO5 の出題方式(JSON) */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "result_format", columnDefinition = "json")
    private Map<String, Object> resultFormat;

    @Enumerated(EnumType.STRING)
    @Column(name = "match_type", length = 10)
    private MatchType matchType;

    @Enumerated(EnumType.STRING)
    @Column(name = "outcome_reason", length = 20)
    private OutcomeReason outcomeReason;

    @Column(name = "ended_at", nullable = false)
    private LocalDateTime endedAt;

    @Column(name = "match_uuid", length = 36)
    private String matchUuid;

    /* ===== lifecycle ===== */
    @PrePersist
    void onCreate() {
        if (endedAt == null) {
            endedAt = LocalDateTime.now().truncatedTo(ChronoUnit.SECONDS);
        }
        if (result == null) result = Boolean.FALSE;
        if (updownRate == null) updownRate = 0;
    }

    /* ===== getters / setters ===== */
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public User getPlayer() { return player; }
    public void setPlayer(User player) { this.player = player; }

    public User getEnemy() { return enemy; }
    public void setEnemy(User enemy) { this.enemy = enemy; }

    public Boolean getResult() { return result; }
    public void setResult(Boolean result) { this.result = result; }

    public Integer getUpdownRate() { return updownRate; }
    public void setUpdownRate(Integer updownRate) { this.updownRate = updownRate; }

    public Integer getRateAfterMatch() { return rateAfterMatch; }
    public void setRateAfterMatch(Integer rateAfterMatch) { this.rateAfterMatch = rateAfterMatch; }

    public String getUseLanguage() { return useLanguage; }
    public void setUseLanguage(String useLanguage) { this.useLanguage = useLanguage; }

    public Map<String, Object> getUseQuestion() { return useQuestion; }
    public void setUseQuestion(Map<String, Object> useQuestion) { this.useQuestion = useQuestion; }

    public Map<String, Object> getResultDetail() { return resultDetail; }
    public void setResultDetail(Map<String, Object> resultDetail) { this.resultDetail = resultDetail; }

    public Map<String, Object> getResultFormat() { return resultFormat; }
    public void setResultFormat(Map<String, Object> resultFormat) { this.resultFormat = resultFormat; }

    public MatchType getMatchType() { return matchType; }
    public void setMatchType(MatchType matchType) { this.matchType = matchType; }

    public OutcomeReason getOutcomeReason() { return outcomeReason; }
    public void setOutcomeReason(OutcomeReason outcomeReason) { this.outcomeReason = outcomeReason; }

    public LocalDateTime getEndedAt() { return endedAt; }
    public void setEndedAt(LocalDateTime endedAt) { this.endedAt = endedAt; }

    public String getMatchUuid() { return matchUuid; }
    public void setMatchUuid(String matchUuid) { this.matchUuid = matchUuid; }
}
