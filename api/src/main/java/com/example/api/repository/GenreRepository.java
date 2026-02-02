package com.example.api.repository;

import com.example.api.entity.Genre;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Genreエンティティへのデータアクセスを行うリポジトリ
 */
@Repository
public interface GenreRepository extends JpaRepository<Genre, Long>, JpaSpecificationExecutor<Genre> {

    /**
     * ジャンル名で検索を行います。
     * @param name ジャンル名
     * @return 該当するジャンル（存在しない場合はEmpty）
     */
    Optional<Genre> findByName(String name);

    /**
     * 指定されたジャンル名が存在するかチェックします。
     * @param name ジャンル名
     * @return 存在する場合はtrue
     */
    boolean existsByName(String name);

    /**
     * 画面表示用に、有効なアーティストが紐付いているジャンルのみを抽出します。
     * * <p><strong>SQLの仕様解説:</strong></p>
     * <ul>
     * <li>{@code DISTINCT}: 1つのジャンルに複数のアーティストがいても、ジャンルは1つだけ返すように重複を除去します。</li>
     * <li>{@code INNER JOIN artist_genre}: 中間テーブルと結合し、紐付けが存在しないジャンルを除外します。</li>
     * <li>{@code INNER JOIN artist}: アーティストテーブルまで結合し、アーティストの状態を確認できるようにします。</li>
     * </ul>
     * * <p><strong>フィルタリング条件:</strong></p>
     * <ul>
     * <li>{@code g.is_active = 1, g.is_deleted = 0}: ジャンル自体が有効であること。</li>
     * <li>{@code a.is_active = 1, a.is_deleted = 0}: 紐付いているアーティストが有効であり、削除されていないこと。
     * これにより「削除済みアーティストしかいないジャンル」が表示されるのを防ぎます。</li>
     * <li>{@code g.name <> 'other'}: システム上の受け皿である 'other' ジャンルは選択肢に出さないようにします。</li>
     * </ul>
     * * @return 表示対象となるジャンルのリスト
     */
    @Query(value = """
        SELECT DISTINCT g.* FROM genre g 
        INNER JOIN artist_genre ag ON g.genre_id = ag.genre_id 
        INNER JOIN artist a ON ag.artist_id = a.artist_id
        WHERE g.is_active = 1 
          AND g.is_deleted = 0
          AND a.is_active = 1
          AND a.is_deleted = 0
          AND g.name <> 'other' 
    """, nativeQuery = true)
    List<Genre> findGenresWithArtists();
}