package com.example.api.service.admin;

import com.example.api.dto.admin.AdminSongRequest;
import com.example.api.dto.admin.AdminSongResponse;
import com.example.api.entity.Artist;
import com.example.api.entity.Song;
import com.example.api.repository.ArtistRepository;
import com.example.api.repository.SongRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class AdminSongService {

    private static final Logger logger = LoggerFactory.getLogger(AdminSongService.class);

    @Autowired
    private SongRepository songRepository;

    @Autowired
    private ArtistRepository artistRepository;

    @PersistenceContext
    private EntityManager entityManager;

    public AdminSongResponse.ListResponse getSongs(
            int page, int size, String idSearch, String songname, String artistName, Boolean isActive,
            LocalDateTime createdFrom, LocalDateTime createdTo, String sortDirection) {
        Sort.Direction direction = parseSortDirection(sortDirection);

        StringBuilder fromClause = new StringBuilder(
                " FROM song s LEFT JOIN artist a ON s.aritst_id = a.artist_id WHERE 1=1");
        Map<String, Object> params = new HashMap<>();

        if (songname != null && !songname.isEmpty()) {
            fromClause.append(" AND s.songname LIKE :songname");
            params.put("songname", "%" + songname + "%");
        }
        if (idSearch != null && !idSearch.isEmpty()) {
            fromClause.append(" AND CAST(s.song_id AS CHAR) = :songId");
            params.put("songId", idSearch);
        }
        if (artistName != null && !artistName.isEmpty()) {
            fromClause.append(" AND a.artist_name LIKE :artistName");
            params.put("artistName", "%" + artistName + "%");
        }
        if (isActive != null) {
            fromClause.append(" AND s.is_active = :isActive");
            params.put("isActive", isActive);
        }
        if (createdFrom != null) {
            fromClause.append(" AND s.created_at >= :createdFrom");
            params.put("createdFrom", createdFrom);
        }
        if (createdTo != null) {
            fromClause.append(" AND s.created_at <= :createdTo");
            params.put("createdTo", createdTo);
        }

        String orderBy = " ORDER BY s.song_id " + (direction == Sort.Direction.ASC ? "ASC" : "DESC");
        String selectSql = "SELECT s.song_id, s.aritst_id, s.songname, s.spotify_track_id, " +
                "s.genius_song_id, s.language, s.is_active, s.created_at, a.artist_name" +
                fromClause + orderBy;
        String countSql = "SELECT COUNT(*)" + fromClause;

        Query dataQuery = entityManager.createNativeQuery(selectSql);
        Query countQuery = entityManager.createNativeQuery(countSql);
        params.forEach((key, value) -> {
            dataQuery.setParameter(key, value);
            countQuery.setParameter(key, value);
        });
        dataQuery.setFirstResult(page * size);
        dataQuery.setMaxResults(size);

        List<Object[]> rows = dataQuery.getResultList();
        List<AdminSongResponse> songs = rows.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        long totalElements = ((Number) countQuery.getSingleResult()).longValue();
        int totalPages = (int) Math.ceil((double) totalElements / size);

        return new AdminSongResponse.ListResponse(songs, page, size, totalElements, totalPages);
    }

    public AdminSongResponse getSong(Long songId) {
        Song song = songRepository.findById(songId)
                .orElseThrow(() -> new IllegalArgumentException("楽曲が見つかりません: " + songId));
        String artistName = null;
        if (song.getArtistId() != null) {
            artistName = artistRepository.findById(song.getArtistId())
                    .map(Artist::getArtistName)
                    .orElse(null);
        }
        return toResponse(song, artistName);
    }

    @Transactional
    public AdminSongResponse createSong(AdminSongRequest request) {
        Song song = new Song();
        updateFromRequest(song, request);
        song = songRepository.save(song);
        logger.info("楽曲作成: {}", song.getSongId());
        return toResponse(song, null);
    }

    @Transactional
    public AdminSongResponse updateSong(Long songId, AdminSongRequest request) {
        Song song = songRepository.findById(songId)
                .orElseThrow(() -> new IllegalArgumentException("楽曲が見つかりません: " + songId));
        updateFromRequest(song, request);
        song = songRepository.save(song);
        logger.info("楽曲更新: {}", songId);
        return toResponse(song, null);
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

    private AdminSongResponse toResponse(Song song, String artistName) {
        AdminSongResponse response = new AdminSongResponse();
        response.setSongId(song.getSongId());
        response.setArtistId(song.getArtistId());
        response.setArtistName(artistName);
        response.setSongname(song.getSongname());
        response.setSpotifyTrackId(song.getSpotifyTrackId());
        response.setGeniusSongId(song.getGeniusSongId());
        response.setLanguage(song.getLanguage());
        response.setIsActive(song.getIsActive());
        response.setCreatedAt(song.getCreated_at());
        return response;
    }

    private AdminSongResponse toResponse(Object[] row) {
        AdminSongResponse response = new AdminSongResponse();
        response.setSongId(row[0] != null ? ((Number) row[0]).longValue() : null);
        response.setArtistId(row[1] != null ? ((Number) row[1]).longValue() : null);
        response.setSongname((String) row[2]);
        response.setSpotifyTrackId((String) row[3]);
        response.setGeniusSongId(row[4] != null ? ((Number) row[4]).longValue() : null);
        response.setLanguage((String) row[5]);
        response.setIsActive(row[6] != null ? (Boolean) row[6] : null);
        response.setCreatedAt(toLocalDateTime(row[7]));
        response.setArtistName((String) row[8]);
        return response;
    }

    private LocalDateTime toLocalDateTime(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof LocalDateTime) {
            return (LocalDateTime) value;
        }
        if (value instanceof java.sql.Timestamp) {
            return ((java.sql.Timestamp) value).toLocalDateTime();
        }
        if (value instanceof java.util.Date) {
            return ((java.util.Date) value).toInstant().atZone(ZoneId.systemDefault()).toLocalDateTime();
        }
        throw new IllegalArgumentException("Unsupported date type: " + value.getClass());
    }

    private Sort.Direction parseSortDirection(String sortDirection) {
        if ("asc".equalsIgnoreCase(sortDirection)) {
            return Sort.Direction.ASC;
        }
        return Sort.Direction.DESC;
    }
}
