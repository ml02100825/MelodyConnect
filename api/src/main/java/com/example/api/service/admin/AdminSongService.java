package com.example.api.service.admin;

import com.example.api.dto.admin.AdminSongRequest;
import com.example.api.dto.admin.AdminSongResponse;
import com.example.api.entity.Song;
import com.example.api.repository.SongRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminSongService {

    private static final Logger logger = LoggerFactory.getLogger(AdminSongService.class);

    @Autowired
    private SongRepository songRepository;

    public AdminSongResponse.ListResponse getSongs(int page, int size, String songname, Long artistId, String language, Boolean isActive) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "songId"));

        Specification<Song> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("isDeleted"), false));

            if (songname != null && !songname.isEmpty()) {
                predicates.add(cb.like(root.get("songname"), "%" + songname + "%"));
            }
            if (artistId != null) {
                predicates.add(cb.equal(root.get("artistId"), artistId));
            }
            if (language != null && !language.isEmpty()) {
                predicates.add(cb.equal(root.get("language"), language));
            }
            if (isActive != null) {
                predicates.add(cb.equal(root.get("isActive"), isActive));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<Song> songPage = songRepository.findAll(spec, pageable);

        List<AdminSongResponse> songs = songPage.getContent().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        return new AdminSongResponse.ListResponse(songs, page, size, songPage.getTotalElements(), songPage.getTotalPages());
    }

    public AdminSongResponse getSong(Long songId) {
        Song song = songRepository.findById(songId)
                .orElseThrow(() -> new IllegalArgumentException("楽曲が見つかりません: " + songId));
        return toResponse(song);
    }

    @Transactional
    public AdminSongResponse createSong(AdminSongRequest request) {
        Song song = new Song();
        updateFromRequest(song, request);
        song = songRepository.save(song);
        logger.info("楽曲作成: {}", song.getSongId());
        return toResponse(song);
    }

    @Transactional
    public AdminSongResponse updateSong(Long songId, AdminSongRequest request) {
        Song song = songRepository.findById(songId)
                .orElseThrow(() -> new IllegalArgumentException("楽曲が見つかりません: " + songId));
        updateFromRequest(song, request);
        song = songRepository.save(song);
        logger.info("楽曲更新: {}", songId);
        return toResponse(song);
    }

    @Transactional
    public void deleteSong(Long songId) {
        Song song = songRepository.findById(songId)
                .orElseThrow(() -> new IllegalArgumentException("楽曲が見つかりません: " + songId));
        song.setIsDeleted(true);
        songRepository.save(song);
        logger.info("楽曲削除: {}", songId);
    }

    @Transactional
    public int enableSongs(List<Long> ids) {
        int count = 0;
        for (Long id : ids) {
            songRepository.findById(id).ifPresent(s -> {
                s.setIsActive(true);
                songRepository.save(s);
            });
            count++;
        }
        return count;
    }

    @Transactional
    public int disableSongs(List<Long> ids) {
        int count = 0;
        for (Long id : ids) {
            songRepository.findById(id).ifPresent(s -> {
                s.setIsActive(false);
                songRepository.save(s);
            });
            count++;
        }
        return count;
    }

    private void updateFromRequest(Song song, AdminSongRequest request) {
        song.setArtistId(request.getArtistId());
        song.setSongname(request.getSongname());
        song.setSpotifyTrackId(request.getSpotifyTrackId());
        song.setGeniusSongId(request.getGeniusSongId());
        song.setLanguage(request.getLanguage());
        song.setIsActive(request.getIsActive());
    }

    private AdminSongResponse toResponse(Song song) {
        AdminSongResponse response = new AdminSongResponse();
        response.setSongId(song.getSongId());
        response.setArtistId(song.getArtistId());
        response.setSongname(song.getSongname());
        response.setSpotifyTrackId(song.getSpotifyTrackId());
        response.setGeniusSongId(song.getGeniusSongId());
        response.setLanguage(song.getLanguage());
        response.setIsActive(song.getIsActive());
        response.setCreatedAt(song.getCreated_at());
        return response;
    }
}
