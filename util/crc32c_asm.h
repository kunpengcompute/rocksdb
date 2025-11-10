#ifndef ROCKSDB_UTIL_CRC32C_ASM_H
#define ROCKSDB_UTIL_CRC32C_ASM_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// 汇编函数声明

uint32_t crc32_iscsi_sve2(const char *BUF,uint64_t LEN,uint32_t wCRC);

uint32_t crc32_iscsi_crc_ext(const char *BUF,uint64_t LEN,uint32_t wCRC);

uint32_t crc32_iscsi_x6(const char *BUF,uint64_t LEN,uint32_t wCRC);

#ifdef __cplusplus
}
#endif

#endif  // ROCKSDB_UTIL_CRC32C_ASM_H
