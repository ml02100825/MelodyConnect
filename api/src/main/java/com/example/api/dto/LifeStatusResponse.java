package com.example.api.dto;

/**
 * ライフ状態レスポンスDTO
 */
public class LifeStatusResponse {
    private int currentLife;
    private int maxLife;
    private long nextRecoveryInSeconds;
    private boolean isSubscriber;

    public LifeStatusResponse() {
    }

    public LifeStatusResponse(int currentLife, int maxLife, long nextRecoveryInSeconds, boolean isSubscriber) {
        this.currentLife = currentLife;
        this.maxLife = maxLife;
        this.nextRecoveryInSeconds = nextRecoveryInSeconds;
        this.isSubscriber = isSubscriber;
    }

    public int getCurrentLife() {
        return currentLife;
    }

    public void setCurrentLife(int currentLife) {
        this.currentLife = currentLife;
    }

    public int getMaxLife() {
        return maxLife;
    }

    public void setMaxLife(int maxLife) {
        this.maxLife = maxLife;
    }

    public long getNextRecoveryInSeconds() {
        return nextRecoveryInSeconds;
    }

    public void setNextRecoveryInSeconds(long nextRecoveryInSeconds) {
        this.nextRecoveryInSeconds = nextRecoveryInSeconds;
    }

    public boolean isSubscriber() {
        return isSubscriber;
    }

    public void setSubscriber(boolean subscriber) {
        isSubscriber = subscriber;
    }
}
