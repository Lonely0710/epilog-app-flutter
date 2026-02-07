import { query } from "./_generated/server";
import { v } from "convex/values";

// Helper to check if years match (within 1 year diff) - duplicated from collections.ts if needed, 
// or shared. For now, we just need to get the media by ID.

export const get = query({
    args: { id: v.id("media") },
    handler: async (ctx, args) => {
        // 1. Get Media
        const media = await ctx.db.get(args.id);
        if (!media) return null;

        // 2. Get User (optional, validation)
        const identity = await ctx.auth.getUserIdentity();
        const userId = identity?.tokenIdentifier;

        // 3. Get Collection Status if user is logged in
        let collectionStatus: any = null;
        let collectionId: string = "";

        if (userId) {
            const collection = await ctx.db
                .query("collections")
                .withIndex("by_user_media", (q) =>
                    q.eq("userId", userId).eq("mediaId", media._id)
                )
                .first();

            if (collection) {
                collectionStatus = collection.status;
                collectionId = collection._id;
            }
        }

        // 4. Get Source Info (to construct full object compliant with Dart entity)
        const allSources = await ctx.db
            .query("media_sources")
            .withIndex("by_media", (q) => q.eq("mediaId", media._id))
            .collect();

        let source = allSources[0]; // default to first
        if (allSources.length > 1) {
            if (media.mediaType === "anime") {
                const bgmSource = allSources.find(s => s.sourceType === "bgm");
                if (bgmSource) source = bgmSource;
            } else {
                const tmdbSource = allSources.find(s => s.sourceType === "tmdb");
                if (tmdbSource) source = tmdbSource;
            }
        }

        const sId = source ? source.sourceId : "";
        const sType = source ? source.sourceType : "";
        const sUrl = source ? source.sourceUrl : "";

        return {
            ...media,
            sourceId: sId,
            sourceType: sType,
            sourceUrl: sUrl,
            collectionId: collectionId,
            watchingStatus: collectionStatus,
            isCollected: !!collectionId,
        };
    },
});

export const getBySource = query({
    args: {
        sourceId: v.string(),
        sourceType: v.string(),
    },
    handler: async (ctx, args) => {
        // 1. Find Media Source
        const mediaSource = await ctx.db
            .query("media_sources")
            .withIndex("by_source", (q) =>
                q.eq("sourceType", args.sourceType).eq("sourceId", args.sourceId)
            )
            .first();

        if (!mediaSource) return null;

        // 2. Get Media
        const media = await ctx.db.get(mediaSource.mediaId);
        if (!media) return null;

        // 3. Get User (optional, validation)
        const identity = await ctx.auth.getUserIdentity();
        const userId = identity?.tokenIdentifier;

        // 4. Get Collection Status if user is logged in
        let collectionStatus: any = null;
        let collectionId: string = "";

        if (userId) {
            const collection = await ctx.db
                .query("collections")
                .withIndex("by_user_media", (q) =>
                    q.eq("userId", userId).eq("mediaId", media._id)
                )
                .first();

            if (collection) {
                collectionStatus = collection.status;
                collectionId = collection._id;
            }
        }

        // 5. Get Source Info (to construct full object compliant with Dart entity)
        // We already have mediaSource but getting all might be safer if we want to prioritize or standard logic
        const allSources = await ctx.db
            .query("media_sources")
            .withIndex("by_media", (q) => q.eq("mediaId", media._id))
            .collect();

        let source = allSources[0]; // default to first
        if (allSources.length > 1) {
            if (media.mediaType === "anime") {
                const bgmSource = allSources.find(s => s.sourceType === "bgm");
                if (bgmSource) source = bgmSource;
            } else {
                const tmdbSource = allSources.find(s => s.sourceType === "tmdb");
                if (tmdbSource) source = tmdbSource;
            }
        }

        const sId = source ? source.sourceId : "";
        const sType = source ? source.sourceType : "";
        const sUrl = source ? source.sourceUrl : "";

        return {
            ...media,
            sourceId: sId,
            sourceType: sType,
            sourceUrl: sUrl,
            collectionId: collectionId,
            watchingStatus: collectionStatus,
            isCollected: !!collectionId,
        };
    },
});

export const getMediaSources = query({
    args: { mediaId: v.id("media") },
    handler: async (ctx, args) => {
        const sources = await ctx.db
            .query("media_sources")
            .withIndex("by_media", (q) => q.eq("mediaId", args.mediaId))
            .collect();

        return sources.map(s => ({
            sourceType: s.sourceType,
            sourceId: s.sourceId,
            sourceUrl: s.sourceUrl,
        }));
    },
});
