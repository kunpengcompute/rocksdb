//  Copyright (c) 2011-present, Facebook, Inc.  All rights reserved
//  This source code is licensed under both the GPLv2 (found in the
//  COPYING file in the root directory) and Apache 2.0 License
//  (found in the LICENSE.Apache file in the root directory).
//
// Copyright (c) 2011 The LevelDB Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file. See the AUTHORS file for names of contributors.

#pragma once

#include <memory>
#include <string>
#include <malloc.h>
#include <mutex>
#include <vector>
#include "ksal/ksal_compact_cache.h"
#include "cache/sharded_cache.h"

namespace ROCKSDB_NAMESPACE {
namespace compact_cache {

struct CompactHandle : public KsalCompactHandle{
    uint32_t GetHash() const {
        return *(uint32_t *)extras;
    }
};

class ALIGN_AS(CACHE_LINE_SIZE) CompactCacheShard final : public CacheShardBase {
public:
    CompactCacheShard(size_t capacity, CacheMetadataChargePolicy metadata_charge_policy);

public:  // Type definitions expected as parameter to ShardedCache
    using HandleImpl = CompactHandle;
    using HashVal = uint32_t;
    using HashCref = uint32_t;

public:  // Function definitions expected as parameter to ShardedCache
    static inline HashVal ComputeHash(const Slice& key) {
        return Lower32of64(GetSliceNPHash64(key));
    }

    inline void SetCapacity(size_t capacity);

    inline void SetStrictCapacityLimit(bool /*strict_capacity_limit*/);

    inline Status Insert(const Slice& key, uint32_t hash, void* value,
                        size_t charge, Cache::DeleterFn deleter,
                        CompactHandle** handle, Cache::Priority /*priority*/);
    inline Status Insert(const Slice& key, uint32_t hash, void* value,
                        const Cache::CacheItemHelper* helper, size_t charge,
                        CompactHandle** handle, Cache::Priority /*priority*/);

    inline CompactHandle* Lookup(const Slice& key, uint32_t /*hash*/,
                    const Cache::CacheItemHelper* /*helper*/,
                    const Cache::CreateCallback& /*create_cb*/,
                    Cache::Priority /*priority*/, bool /*wait*/, Statistics* /*stats*/);

    inline CompactHandle* Lookup(const Slice& key, uint32_t /*hash*/);

    inline bool Release(CompactHandle* handle, bool /*useful*/, bool /*erase_if_last_ref*/);

    inline bool Ref(CompactHandle* handle);

    inline void Erase(const Slice& key, uint32_t /*hash*/);

    inline bool IsReady(CompactHandle* /*handle*/);

    inline void Wait(CompactHandle* /*handle*/);

    inline size_t GetUsage() const;

    inline size_t GetPinnedUsage() const;

    inline size_t GetOccupancyCount() const;

    inline size_t GetTableAddressCount() const;

    inline void ApplyToSomeEntries(
        const std::function<void(const Slice& key, void* value, size_t charge, DeleterFn deleter)>& /*callback*/,
        size_t /*average_entries_per_lock*/, size_t* /*state*/);

    inline void EraseUnRefEntries();

private:
    KsalCompactCache cacheInternal;
};

class CompactCache
#ifdef NDEBUG
    final
#endif
    : public ShardedCache<CompactCacheShard> {
public:
    CompactCache(size_t capacity, int num_shard_bits,  bool strict_capacity_limit,
                std::shared_ptr<MemoryAllocator> memory_allocator = nullptr,
            CacheMetadataChargePolicy metadata_charge_policy = kDontChargeCacheMetadata);
    const char* Name() const override { return "CompactCache"; }
    void* Value(Handle* handle) override;
    size_t GetCharge(Handle* handle) const override;
    DeleterFn GetDeleter(Handle* handle) const override;
};

}  // namespace Compact_cache

using CompactCache = compact_cache::CompactCache;
using CompactCacheShard = compact_cache::CompactCacheShard;

}  // namespace ROCKSDB_NAMESPACE
