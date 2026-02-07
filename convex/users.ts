import { v } from "convex/values";
import { mutation, query } from "./_generated/server";

/**
 * Store or update user profile
 */
export const storeUser = mutation({
    args: {
        name: v.string(),
        avatarStorageId: v.optional(v.string()), // Storage ID from upload
    },
    handler: async (ctx, args) => {
        const identity = await ctx.auth.getUserIdentity();
        if (!identity) {
            throw new Error("Called storeUser without authentication present");
        }

        // Check if we have an existing user
        const user = await ctx.db
            .query("users")
            .withIndex("by_token", (q) => q.eq("tokenIdentifier", identity.tokenIdentifier))
            .unique();

        let avatarUrl: string | undefined;
        if (args.avatarStorageId) {
            // Generate a URL for the uploaded file
            // NOTE: This URL is ephemeral or permanent depending on Convex config, 
            // typically storage URLs are valid.
            const url = await ctx.storage.getUrl(args.avatarStorageId);
            if (url) {
                avatarUrl = url;
            }
        }

        if (user !== null) {
            // Update existing user
            await ctx.db.patch(user._id, {
                name: args.name,
                // Only update avatar if a new one was provided, otherwise keep existing
                ...(avatarUrl ? { avatarUrl } : {}),
            });
            return user._id;
        } else {
            // Create new user
            const newUserId = await ctx.db.insert("users", {
                tokenIdentifier: identity.tokenIdentifier,
                name: args.name,
                avatarUrl: avatarUrl,
            });
            return newUserId;
        }
    },
});

/**
 * Generate a URL for uploading a file to Convex Storage
 */
export const generateUploadUrl = mutation({
    args: {},
    handler: async (ctx, args) => {
        const identity = await ctx.auth.getUserIdentity();
        if (!identity) {
            throw new Error("Unauthenticated call to generateUploadUrl");
        }
        return await ctx.storage.generateUploadUrl();
    },
});

/**
 * Get current user profile
 */
export const currentUser = query({
    args: {},
    handler: async (ctx) => {
        const identity = await ctx.auth.getUserIdentity();
        if (!identity) {
            return null;
        }
        return await ctx.db
            .query("users")
            .withIndex("by_token", (q) => q.eq("tokenIdentifier", identity.tokenIdentifier))
            .unique();
    },
});
