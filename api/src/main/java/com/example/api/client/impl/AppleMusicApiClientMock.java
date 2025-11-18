package com.example.api.client.impl;

import com.example.api.client.AppleMusicApiClient;
import com.example.api.entity.Song;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * Apple Music API Client のモック実装
 * TODO: 実際のAPI統合時に削除または @Profile("mock") を追加
 */
@Component
public class AppleMusicApiClientMock implements AppleMusicApiClient {

    @Override
    public Song getRandomSongByArtist(Integer artistId) {
        return createMockSong();
    }

    @Override
    public Song getRandomSongByGenre(String genreName) {
        return createMockSong();
    }

    @Override
    public Song getRandomSong() {
        return createMockSong();
    }

    private Song createMockSong() {
        Song mockSong = new Song();
        mockSong.setSong_id(1L);
        mockSong.setAritst_id(1L);
        mockSong.setSongname("Mock Song Title");
        mockSong.setSpotify_track_id("mock_spotify_id");
        mockSong.setGenius_song_id(12345L);
        mockSong.setLanguage("English");
        mockSong.setGenre("Pop");
        mockSong.setCreated_at(LocalDateTime.now());
        return mockSong;
    }
}
