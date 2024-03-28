//  Copyright (c) 2011-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under both the GPLv2 (found in the
//  COPYING file in the root directory) and Apache 2.0 License
//  (found in the LICENSE.Apache file in the root directory).
//
// Copyright (c) 2011 The LevelDB Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICEIsReadyNSE file. See the AUTHORS file for names of contributors.

#include "cache/compact_cache_interface.h"

#include <cassert>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <utility>

void RocksdbDeleter(void *deleter, void *value)
{
    ((rocksdb::Cache::DeleterFn)deleter)(NULL, value);
}

namespace ROCKSDB_NAMESPACE {
namespace compact_cache {

void CompactCacheShard::SetCapacity(size_t capacity) {
    cacheInternal.SetCapacity(capacity);
};

void CompactCacheShard::SetStrictCapacityLimit(bool /*strict_capacity_limit*/) {
    return;
}

Status CompactCacheShard::Insert(const Slice& key, uint32_t hash, void* value,
                    size_t charge, Cache::DeleterFn deleter,
                    CompactHandle** handle, Cache::Priority /*priority*/) {
    bool overwrite = cacheInternal.Insert(std::string(key.data(),key.size()), value, charge, (void *)deleter, (CompactHandleInternal **)handle, (int8_t *)&hash, sizeof(uint32_t));
    return overwrite?Status::OkOverwritten():Status::OK();
}

Status CompactCacheShard::Insert(const Slice& key, uint32_t hash, void* value,
                    const Cache::CacheItemHelper* helper, size_t charge,
                    CompactHandle** handle, Cache::Priority /*priority*/) {
    bool overwrite = cacheInternal.Insert(std::string(key.data(),key.size()), value, charge,  (void *)helper->del_cb, (CompactHandleInternal **)handle, (int8_t *)&hash, sizeof(uint32_t));
    return overwrite?Status::OkOverwritten():Status::OK();
}

CompactHandle* CompactCacheShard::Lookup(const Slice& key, uint32_t /*hash*/,
                const Cache::CacheItemHelper* /*helper*/,
                const Cache::CreateCallback& /*create_cb*/,
                Cache::Priority /*priority*/, bool /*wait*/, Statistics* /*stats*/) {
    return static_cast<CompactHandle*>(cacheInternal.Lookup(std::string(key.data(),key.size())));
}

CompactHandle* CompactCacheShard::Lookup(const Slice& key, uint32_t /*hash*/) {
    return static_cast<CompactHandle*>(cacheInternal.Lookup(std::string(key.data(),key.size())));
}

bool CompactCacheShard::Release(CompactHandle* handle, bool /*useful*/, bool /*erase_if_last_ref*/) {
    return cacheInternal.Release(handle);
}

bool CompactCacheShard::Ref(CompactHandle* handle) {
    cacheInternal.Ref(handle);
    return true;
}

void CompactCacheShard::Erase(const Slice& key, uint32_t /*hash*/) {
    cacheInternal.Erase(std::string(key.data(),key.size()));
}

bool CompactCacheShard::IsReady(CompactHandle* /*handle*/) {return true;};

void CompactCacheShard::Wait(CompactHandle* /*handle*/) {}

size_t CompactCacheShard::GetUsage() const{
    return cacheInternal.GetUsage();
}

size_t CompactCacheShard::GetPinnedUsage() const{
    return 0;
}

size_t CompactCacheShard::GetOccupancyCount() const {
    return cacheInternal.GetOccupancyCount();
};

size_t CompactCacheShard::GetTableAddressCount() const {
    return 0;
};

void CompactCacheShard::ApplyToSomeEntries(
    const std::function<void(const Slice& key, void* value, size_t charge, DeleterFn deleter)>& /*callback*/,
    size_t /*average_entries_per_lock*/, size_t* /*state*/) {
    //TODO:此处不易适配，此处认为该函数不被调用。
    assert(0);
}

void CompactCacheShard::EraseUnRefEntries() {
    cacheInternal.EraseUnRefEntries();
}

CompactCacheShard::CompactCacheShard(size_t capacity, CacheMetadataChargePolicy metadata_charge_policy)
    : CacheShardBase(metadata_charge_policy), 
    cacheInternal(capacity) {
}

CompactCache::CompactCache(size_t capacity, int num_shard_bits, bool strict_capacity_limit,
                    std::shared_ptr<MemoryAllocator> allocator,
                   CacheMetadataChargePolicy metadata_charge_policy)
    : ShardedCache(capacity, num_shard_bits, strict_capacity_limit,
                   std::move(allocator)) {
  size_t per_shard = GetPerShardCapacity();
  InitShards([=](CompactCacheShard* cs) {
    new (cs) CompactCacheShard(
        per_shard, metadata_charge_policy);
  });
  CompactHandleInternal::InternalDeleter=RocksdbDeleter;
}

void* CompactCache::Value(Handle* handle) {
  return reinterpret_cast<const CompactHandle*>(handle)->value;
}

size_t CompactCache::GetCharge(Handle* handle) const {
  return reinterpret_cast<const CompactHandle*>(handle)->GetCharge();
}

Cache::DeleterFn CompactCache::GetDeleter(Handle* handle) const {
  auto h = reinterpret_cast<const CompactHandle*>(handle);
  return (Cache::DeleterFn)h->deleter;
}

}

std::shared_ptr<Cache> NewCompactCache(
    size_t capacity, int num_shard_bits, bool strict_capacity_limit, std::shared_ptr<MemoryAllocator> memory_allocator,
    CacheMetadataChargePolicy metadata_charge_policy) {
  if (num_shard_bits >= 20) {
    return nullptr;  // The cache cannot be sharded into too many fine pieces.
  }
  if (num_shard_bits < 0) {
    num_shard_bits = GetDefaultCacheShardBits(capacity);
  }
  return std::make_shared<CompactCache>(
      capacity, num_shard_bits, strict_capacity_limit, std::move(memory_allocator),
      metadata_charge_policy);
}

std::shared_ptr<Cache> NewCompactCache(const CompactCacheOptions& cache_opts) {
  return NewCompactCache(cache_opts.capacity, cache_opts.num_shard_bits,
                    cache_opts.strict_capacity_limit,
                    cache_opts.memory_allocator, cache_opts.metadata_charge_policy);
}

}  // namespace ROCKSDB_NAMESPACE
