"use node";
import { action } from "./_generated/server";
import { v } from "convex/values";
import * as cheerio from "cheerio";

// ============================================================================
// Type Definitions
// ============================================================================

interface MediaItem {
    sourceType: string;
    sourceId: string;
    sourceUrl: string;
    mediaType: string;
    titleZh: string;
    titleOriginal: string;
    releaseDate: string;
    duration: string;
    year: string;
    posterUrl: string;
    summary: string;
    staff: string;
    directors: string[];
    actors: string[];
    rating: number;
    ratingDouban: number;
    ratingImdb: number;
    ratingBangumi: number;
    ratingMaoyan: number;

    wish: string;
    isNew: boolean;
    matchCount?: number;
}

// ============================================================================
// Main Action
// ============================================================================

export const search = action({
    args: { query: v.string(), type: v.string() },
    handler: async (ctx, args) => {
        const { query, type } = args;
        if (!query) return [];

        console.log(`Searching for: ${query} (Type: ${type})`);

        // Parallel execution based on type
        const tasks: Promise<MediaItem[]>[] = [];

        if (type === 'movie' || type === 'all') {
            tasks.push(searchTmdb(query));
            tasks.push(searchMaoyan(query));
            tasks.push(searchDouban(query));
        }

        if (type === 'anime' || type === 'all') {
            tasks.push(searchBangumi(query));
        }

        const resultsArray = await Promise.all(tasks);
        const flattenedResults: MediaItem[] = [];
        resultsArray.forEach(r => flattenedResults.push(...r));

        // Deduplication and Merging
        return mergeAndDeduplicate(flattenedResults);
    },
});

// ============================================================================
// TMDb Search
// ============================================================================

async function searchTmdb(query: string): Promise<MediaItem[]> {
    const tmdbToken = process.env.TMDB_ACCESS_TOKEN;
    if (!tmdbToken) {
        console.error("TMDB_ACCESS_TOKEN not set");
        return [];
    }

    try {
        const searchUrl = `https://api.themoviedb.org/3/search/multi?query=${encodeURIComponent(query)}&language=zh-CN&include_adult=false`;
        const response = await fetch(searchUrl, {
            headers: {
                Authorization: `Bearer ${tmdbToken}`,
                "Content-Type": "application/json",
            },
        });

        if (!response.ok) return [];

        const data = await response.json();
        const results = data.results || [];

        // Filter and Limit
        const filtered = results
            .filter((item: any) => item.media_type === "movie" || item.media_type === "tv")
            .slice(0, 8);

        // Fetch details in parallel
        const detailedItems = await Promise.all(
            filtered.map((item: any) => fetchTmdbDetails(item, tmdbToken))
        );

        return detailedItems.filter((item): item is MediaItem => item !== null);
    } catch (e) {
        console.error("TMDb search error:", e);
        return [];
    }
}

async function fetchTmdbDetails(item: any, token: string): Promise<MediaItem | null> {
    try {
        const mediaType = item.media_type;
        const id = item.id;
        const detailUrl = `https://api.themoviedb.org/3/${mediaType}/${id}?language=zh-CN&append_to_response=credits`;

        const response = await fetch(detailUrl, {
            headers: { Authorization: `Bearer ${token}` },
        });

        if (!response.ok) return tmdbItemToMedia(item, mediaType);

        const detail = await response.json();
        return tmdbItemToMedia(detail, mediaType);
    } catch (e) {
        return tmdbItemToMedia(item, item.media_type);
    }
}

function tmdbItemToMedia(item: any, mediaType: string): MediaItem {
    const isMovie = mediaType === "movie";
    const id = item.id?.toString() || "";
    const titleZh = isMovie ? item.title : item.name;
    const titleOriginal = isMovie ? item.original_title : item.original_name;
    const releaseDate = isMovie ? (item.release_date || "未知日期") : (item.first_air_date || "未知日期");
    let year = "----";
    if (releaseDate && releaseDate.length >= 4) year = releaseDate.substring(0, 4);

    const posterPath = item.poster_path;
    const posterUrl = posterPath ? `https://image.tmdb.org/t/p/w500${posterPath}` : "";

    let duration = "未知";
    if (isMovie && item.runtime) duration = `${item.runtime}分钟`;
    else if (!isMovie) {
        // Prioritize number_of_episodes for TV shows (shows total episodes like "共12集")
        if (item.number_of_episodes) {
            // Check if anime (Animation genre id = 16)
            const genreIds = item.genre_ids || item.genres?.map((g: any) => g.id) || [];
            const isAnime = genreIds.includes(16);
            duration = isAnime ? `共${item.number_of_episodes}话` : `共${item.number_of_episodes}集`;
        } else if (item.episode_run_time?.length) {
            // Fallback to episode runtime only if no episode count
            duration = `${item.episode_run_time[0]}分钟/集`;
        }
    }

    let directors: string[] = [];
    let actors: string[] = [];
    if (item.credits) {
        directors = (item.credits.crew || [])
            .filter((m: any) => m.job === "Director")
            .map((m: any) => m.name).slice(0, 3);
        actors = (item.credits.cast || []).map((m: any) => m.name).slice(0, 5);
    }

    return {
        sourceType: "tmdb",
        sourceId: id,
        sourceUrl: `https://www.themoviedb.org/${mediaType}/${id}`,
        mediaType: mediaType,
        titleZh: titleZh || "未知标题",
        titleOriginal: titleOriginal || "",
        releaseDate,
        duration,
        year,
        posterUrl,
        summary: item.overview || "暂无简介",
        staff: "",
        directors,
        actors,
        rating: item.vote_average || 0,
        ratingDouban: 0,
        ratingImdb: item.vote_average || 0,
        ratingBangumi: 0,
        ratingMaoyan: 0,

        wish: "",
        isNew: false,
        matchCount: 1,
    };
}

// ============================================================================
// Bangumi Search
// ============================================================================

async function searchBangumi(query: string): Promise<MediaItem[]> {
    try {
        const url = `https://bgm.tv/subject_search/${encodeURIComponent(query)}?cat=2`;
        const response = await fetch(url, {
            headers: {
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                "Cookie": "chii_searchDateLine=0",
            },
        });

        if (!response.ok) return [];

        const html = await response.text();
        const $ = cheerio.load(html);
        const items: MediaItem[] = [];
        $("#browserItemList > li").slice(0, 8).each((_, element) => {
            const item = parseBangumiItem($, element);
            if (item) items.push(item);
        });

        // Parallel detail fetch for summary
        const detailedItems = await Promise.all(
            items.map(item => fetchBangumiDetails(item))
        );

        return detailedItems;
    } catch (e) {
        console.error("Bangumi search error:", e);
        return [];
    }
}

async function fetchBangumiDetails(item: MediaItem): Promise<MediaItem> {
    try {
        const response = await fetch(item.sourceUrl, {
            headers: {
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                "Cookie": "chii_searchDateLine=0",
            },
        });

        if (!response.ok) return item;

        const html = await response.text();
        const $ = cheerio.load(html);

        // Parse Summary
        const summary = $("#subject_summary").text().trim();
        if (summary) item.summary = summary;

        // Parse Infobox for detailed info (staff, episodes, etc.)
        const infobox = $("#infobox");
        if (infobox.length) {
            const info: Record<string, string> = {};
            infobox.find("li").each((_, el) => {
                const text = $(el).text().trim();
                const parts = text.split(":");
                if (parts.length >= 2) {
                    const key = parts[0].trim();
                    const value = parts.slice(1).join(":").trim();
                    info[key] = value;
                }
            });

            // Director
            if (info["导演"]) {
                item.directors = [info["导演"]];
            }

            // Staff (construct from various roles if original staff was empty or weak)
            // Priority: Director, Script, Character Design, Music, Animation Production
            const staffRoles = ["导演", "脚本", "人物设定", "音乐", "动画制作", "原画", "原作"];
            const staffParts: string[] = [];

            for (const role of staffRoles) {
                if (info[role]) {
                    staffParts.push(`${role}: ${info[role]}`);
                }
            }

            if (staffParts.length > 0) {
                // If we found detailed staff info, overwrite or append?
                // Overwriting is safer as search result staff might be truncated or messy
                item.staff = staffParts.join(" / ");
            }

            // Cast / Actors (演出)
            if (info["演出"]) {
                const castStr = info["演出"];
                // Split by common separators: 、 / , ， space
                const actors = castStr.split(/、|\/|,|，| /).map(s => s.trim()).filter(s => s);
                item.actors = actors;
            }

            // Episodes / Duration
            if (info["话数"]) {
                const epCount = info["话数"];
                if (epCount && epCount !== "*") {
                    item.duration = `共${epCount}话`;
                }
            }

            // Chinese Title (if missing or matches original)
            if (info["中文名"] && (!item.titleZh || item.titleZh === item.titleOriginal)) {
                item.titleZh = info["中文名"];
            }

            // Release Date (放送开始)
            if (info["放送开始"]) {
                // Format usually "2012年4月1日"
                const dateStr = info["放送开始"];
                item.releaseDate = dateStr.replace(/年|月/g, "-").replace(/日/g, "");
                // Update year if needed
                const yearMatch = dateStr.match(/^\d{4}/);
                if (yearMatch) item.year = yearMatch[0];
            }
        }

        // Parse more detailed staff if needed?
        // For now, search list staff parsing is okay, but we can refine it here if we want full cast.
        // But user said BGM doesn't store actors in staff, so we rely on TMDB for that.

        return item;
    } catch (e) {
        console.error(`Error fetching details for ${item.titleZh}:`, e);
        return item;
    }
}

function parseBangumiItem($: cheerio.CheerioAPI, element: any): MediaItem | null {
    try {
        const $item = $(element);
        const titleElement = $item.find("h3 > a.l");
        if (!titleElement.length) return null;

        const href = titleElement.attr("href") || "";
        const sourceId = href.split("/").pop() || "";
        const titleZh = titleElement.text().trim();
        const titleOriginal = $item.find("h3 > small.grey").text().trim();

        // Poster
        let posterUrl = "";
        const imgSrc = $item.find(".subjectCover img").attr("src") || "";
        if (imgSrc) posterUrl = "https:" + imgSrc.replace(/\/s\/|\/m\//, "/l/");

        // Info
        const infoText = $item.find(".info.tip").text().trim();
        let rating = parseFloat($item.find(".rateInfo small.fade").text()) || 0;

        // Simple parsing for now
        let year = "----";
        const yearMatch = infoText.match(/(\d{4})年/);
        if (yearMatch) year = yearMatch[1];

        // Clean staff info: remove date parts
        const cleanStaff = infoText.split(" / ")
            .filter(part => !part.match(/^\d{4}年/)) // Remove "2014年..."
            .join(" / ");

        // Parse Directors (first part of staff)
        const directors: string[] = [];
        const staffParts = cleanStaff.split("/");
        if (staffParts.length > 0 && staffParts[0].trim()) {
            directors.push(staffParts[0].trim());
        }

        return {
            sourceType: "bgm",
            sourceId,
            sourceUrl: `https://bgm.tv/subject/${sourceId}`,
            mediaType: "anime",
            titleZh,
            titleOriginal,
            releaseDate: year !== "----" ? `${year}-01-01` : "未知日期",
            duration: parseBangumiDuration(infoText),
            year,
            posterUrl,
            summary: "暂无简介", // Will be updated by detail fetch
            staff: cleanStaff,
            directors, // Populated from staff
            actors: [],
            rating,
            ratingDouban: 0,
            ratingImdb: 0,
            ratingBangumi: rating,
            ratingMaoyan: 0,

            wish: "",
            isNew: false,
            matchCount: 1
        };
    } catch (e) {
        return null;
    }
}

// Helper to parse duration/episodes from Bangumi info text
function parseBangumiDuration(infoText: string): string {
    const parts = infoText.split(" / ");
    for (const part of parts) {
        if (part.match(/^\d+话$/)) return part; // Exact match "12话"
        if (part.match(/共\d+话/)) return part; // "共12话"
        if (part.match(/\d+小时/) || part.match(/\d+分钟/)) return part;
    }
    return "未知";
}

// ============================================================================
// Maoyan Search
// ============================================================================

async function searchMaoyan(query: string): Promise<MediaItem[]> {
    try {
        const url = `https://m.maoyan.com/ajax/search?kw=${encodeURIComponent(query)}&cityId=1&stype=-1`;

        const response = await fetch(url, {
            headers: {
                "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1",
            },
        });

        if (!response.ok) return [];

        const data = await response.json();
        const items: MediaItem[] = [];

        if (data?.movies?.list) {
            for (const item of data.movies.list.slice(0, 8)) {
                try {
                    const media = maoyanItemToMedia(item);
                    items.push(media);
                } catch (e) {
                    console.error("Error parsing Maoyan item:", e);
                }
            }
        }

        // Parallel detail fetch for directors
        const detailedItems = await Promise.all(
            items.map(item => fetchMaoyanDetails(item))
        );

        return detailedItems;
    } catch (e) {
        console.error("Maoyan search error:", e);
        return [];
    }
}

async function fetchMaoyanDetails(item: MediaItem): Promise<MediaItem> {
    try {
        const url = `https://m.maoyan.com/ajax/detailmovie?movieId=${item.sourceId}`;
        const response = await fetch(url, {
            headers: {
                "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1",
            },
        });

        if (!response.ok) return item;

        const data = await response.json();
        const detail = data?.detailMovie;

        if (detail) {
            // Update director if available
            if (detail.dir) {
                // Maoyan 'dir' is usually a string like "张三/李四" or just "张三"
                // Sometimes it might be separated by space or other chars?
                // Let's assume standard format or just use the string as is for now,
                // but we want a list.
                // The search result parsing assumed 'dir' was a string.
                // Detail API might return it as a string or structure.
                // Looking at typical Maoyan API, 'dir' in detail might be a string.
                const dirStr = detail.dir;
                item.directors = dirStr.split(/[\/\s,]+/).filter((s: string) => s.trim());

                // Update staff if needed, but current staff string is constructed from dir/star
                // Reconstruct staff to include updated director?
                let staff = "";
                if (detail.dir) staff += `导演: ${detail.dir} `;
                if (detail.star) staff += `主演: ${detail.star}`;
                if (staff) item.staff = staff;
            }
            // Update summary if available and not present
            if (detail.dra && (!item.summary || item.summary === "暂无简介")) {
                // Remove HTML tags if any (Maoyan summary usually plain text but safe to check)
                item.summary = detail.dra.replace(/<[^>]*>/g, "");
            }
        }

        return item;
    } catch (e) {
        console.error(`Error fetching Maoyan details for ${item.titleZh}:`, e);
        return item;
    }
}

function maoyanItemToMedia(item: any): MediaItem {
    const id = item.id?.toString() || "";
    const title = item.nm || "未知标题";
    const originalTitle = item.enm || "";
    const score = parseFloat(item.sc) || 0;
    const wish = item.wish?.toString() || "0";

    // Poster
    let poster = item.img || "";
    if (poster.includes("/w.h/")) {
        poster = poster.replace("/w.h/", "/");
    }

    const pubDesc = item.pubDesc || "";
    const releaseDate = item.rt || "";

    let year = "----";
    if (releaseDate && releaseDate.length >= 4) {
        year = releaseDate.substring(0, 4);
    } else if (pubDesc) {
        const yearMatch = pubDesc.match(/\d{4}/);
        if (yearMatch) year = yearMatch[0];
    }

    const director = item.dir || "";
    const actorsStr = item.star || "";
    const genresStr = item.cat || "";
    const dur = item.dur || 0;

    const isNew = item.showStateButton?.content === "购票" || item.showStateButton?.content === "预售";

    let staff = "";
    if (director) staff += `导演: ${director} `;
    if (actorsStr) staff += `主演: ${actorsStr}`;

    const genres = genresStr.split(",").map((s: string) => s.trim()).filter((s: string) => s);
    const actors = actorsStr.split(",").map((s: string) => s.trim()).filter((s: string) => s);

    return {
        sourceType: "maoyan",
        sourceId: id,
        sourceUrl: `https://m.maoyan.com/movie/${id}`,
        mediaType: "movie",
        titleZh: title,
        titleOriginal: originalTitle,
        releaseDate: releaseDate,
        duration: dur ? `${dur}分钟` : "未知",
        year: year,
        posterUrl: poster,
        summary: "暂无简介",
        staff: staff || "暂无制作信息",
        directors: director ? [director] : [],
        actors: actors,
        rating: score,
        ratingDouban: 0,
        ratingImdb: 0,
        ratingBangumi: 0,
        ratingMaoyan: score,

        wish: wish,
        isNew: isNew,
        matchCount: 1,
    };
}

// ============================================================================
// Douban Search
// ============================================================================

async function searchDouban(query: string): Promise<MediaItem[]> {
    try {
        const url = `https://www.douban.com/search?cat=1002&q=${encodeURIComponent(query)}`;

        const response = await fetch(url, {
            headers: {
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            },
        });

        if (!response.ok) return [];

        const html = await response.text();
        const $ = cheerio.load(html);
        const results: MediaItem[] = [];

        $(".result-list .result").slice(0, 8).each((_, element) => {
            try {
                const $item = $(element);
                const titleLink = $item.find("h3 a");
                const onclick = titleLink.attr("onclick") || "";
                const idMatch = onclick.match(/sid:\s*(\d+)/);
                if (!idMatch) return;

                const sourceId = idMatch[1];
                const titleZh = titleLink.text().trim() || "未知标题";
                const rating = parseFloat($item.find(".rating_nums").text()) || 0;

                const subjectCast = $item.find(".subject-cast").text().trim();
                let year = "----";
                const yearMatch = subjectCast.match(/\d{4}/);
                if (yearMatch) year = yearMatch[0];

                results.push({
                    sourceType: "douban",
                    sourceId: sourceId,
                    sourceUrl: `https://movie.douban.com/subject/${sourceId}`,
                    mediaType: "movie",
                    titleZh: titleZh,
                    titleOriginal: "",
                    releaseDate: "未知日期",
                    duration: "未知",
                    year: year,
                    posterUrl: "",
                    summary: "暂无简介",
                    staff: subjectCast,
                    directors: [],
                    actors: [],
                    rating: rating,
                    ratingDouban: rating,
                    ratingImdb: 0,
                    ratingBangumi: 0,
                    ratingMaoyan: 0,

                    wish: "",
                    isNew: false,
                    matchCount: 1,
                });
            } catch (e) {
                console.error("Error parsing Douban item:", e);
            }
        });

        return results;
    } catch (e) {
        console.error("Douban search error:", e);
        return [];
    }
}

// ============================================================================
// Merging & Deduplication
// ============================================================================

function mergeAndDeduplicate(items: MediaItem[]): MediaItem[] {
    if (items.length === 0) return [];

    // Calculate completeness for each item first
    const scoredItems = items.map(item => ({
        ...item,
        score: calculateCompletenessScore(item)
    }));

    // Sort by score descending
    scoredItems.sort((a, b) => b.score - a.score);

    const merged: MediaItem[] = [];

    for (const item of scoredItems) {
        let found = false;

        // Try to find an existing match in the merged list
        for (let i = 0; i < merged.length; i++) {
            if (areSameMedia(merged[i], item)) {
                merged[i] = mergeItems(merged[i], item);
                found = true;
                break;
            }
        }

        if (!found) {
            merged.push(item);
        }
    }

    return merged;
}

function normalizeTitle(title: string): string {
    if (!title) return "";
    return title.toLowerCase()
        .replace(/\s+/g, "")
        .replace(/[。、，！？：；""''「」『』【】（）\[\]().,!?:;'"－—·～~]/g, "")
        .replace(/[^\w\u4e00-\u9fa5\u3040-\u309f\u30a0-\u30ff]/g, "") // Keep only word chars and CJK
        .trim();
}

function areTitlesSimilar(title1: string, title2: string): boolean {
    const norm1 = normalizeTitle(title1);
    const norm2 = normalizeTitle(title2);
    if (!norm1 || !norm2) return false;
    return norm1 === norm2; // Exact match only - no substring matching
}

function areYearsSimilar(year1: string, year2: string): boolean {
    if (!year1 || !year2 || year1 === "----" || year2 === "----") return true;
    return year1 === year2; // Exact year match only
}

function areSameMedia(item1: MediaItem, item2: MediaItem): boolean {
    // If IDs match (and source matches), they are obviously the same
    if (item1.sourceType === item2.sourceType && item1.sourceId === item2.sourceId) return true;

    // Check title similarity
    if (!areTitlesSimilar(item1.titleZh, item2.titleZh)) return false;

    // Check year similarity
    if (!areYearsSimilar(item1.year, item2.year)) return false;

    // Media type check (be lenient if one is generic 'movie' vs 'tv' sometimes)
    // But usually we don't merge anime into movie unless titles match perfectly
    if (item1.mediaType !== item2.mediaType) {
        // Exception: some sources mark anime as 'tv'
        const isAnime1 = item1.mediaType === 'anime';
        const isAnime2 = item2.mediaType === 'anime';
        // If one is anime and the other is movie/tv, proceed with caution?
        // For now, strict type check except for tv/anime ambiguity could be complex
        // Let's stick to title+year mainly.
        // If titles are identical, we assume same.
    }

    return true;
}

function calculateCompletenessScore(item: MediaItem): number {
    let score = 0;
    if (item.posterUrl) score += 20;
    if (item.summary && item.summary !== "暂无简介" && item.summary.length > 10) score += 15;
    if (item.ratingImdb > 0) score += 10;
    if (item.ratingDouban > 0) score += 10;
    if (item.ratingBangumi > 0) score += 10;
    if (item.ratingMaoyan > 0) score += 8;
    if (item.directors && item.directors.length > 0) score += 8;

    if (item.sourceType === "tmdb") score += 10;
    return score;
}

function mergeItems(primary: MediaItem, secondary: MediaItem): MediaItem {
    const merged = { ...primary };
    merged.matchCount = (primary.matchCount || 1) + (secondary.matchCount || 1);

    // Merge ratings
    if (merged.ratingImdb === 0) merged.ratingImdb = secondary.ratingImdb;
    if (merged.ratingDouban === 0) merged.ratingDouban = secondary.ratingDouban;
    if (merged.ratingBangumi === 0) merged.ratingBangumi = secondary.ratingBangumi;
    if (merged.ratingMaoyan === 0) merged.ratingMaoyan = secondary.ratingMaoyan;

    // Fill missing info
    if (!merged.posterUrl) merged.posterUrl = secondary.posterUrl;
    if (!merged.summary || merged.summary === "暂无简介") merged.summary = secondary.summary;
    if (merged.year === "----") merged.year = secondary.year;

    const bgmItem = primary.sourceType === 'bgm' ? primary : (secondary.sourceType === 'bgm' ? secondary : null);
    const tmdbItem = primary.sourceType === 'tmdb' ? primary : (secondary.sourceType === 'tmdb' ? secondary : null);

    if (bgmItem && bgmItem.mediaType === 'anime') {
        // Prioritize Bangumi source info for anime - critical for character loading
        merged.sourceType = 'bgm';
        merged.sourceId = bgmItem.sourceId;
        merged.sourceUrl = bgmItem.sourceUrl;

        // Use Bangumi's posterUrl and duration if available
        if (bgmItem.posterUrl) merged.posterUrl = bgmItem.posterUrl;
        if (bgmItem.duration && bgmItem.duration !== "未知") merged.duration = bgmItem.duration;

        // Use Bangumi staff text
        merged.staff = bgmItem.staff;

        // Parse directors from Bangumi staff.info (text before first "/")
        const staffParts = bgmItem.staff.split('/');
        if (staffParts.length > 0 && staffParts[0].trim()) {
            merged.directors = [staffParts[0].trim()];
        } else {
            merged.directors = [];
        }

        // Use TMDB actors if available
        if (tmdbItem && tmdbItem.actors.length > 0) {
            merged.actors = tmdbItem.actors;
        } else {
            merged.actors = [];
        }
    }

    return merged;
}
