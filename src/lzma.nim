
# These are 3 header files merged into one: common.h, compress.h, decompress.h
{.emit:"""
/*
 * Written in 2009 by Lloyd Hilaiel
 *
 * License
 * 
 * All the cruft you find here is public domain.  You don't have to credit
 * anyone to use this code, but my personal request is that you mention
 * Igor Pavlov for his hard, high quality work.
 *
 * easylzma/common.h - definitions common to both compression and
 *                     decompression
 */


#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif  

#define EASYLZMA_API

/** error codes */

/** no error */
#define ELZMA_E_OK                               0
/** bad parameters passed to an ELZMA function */
#define ELZMA_E_BAD_PARAMS                      10
/** could not initialize the encode with configured parameters. */
#define ELZMA_E_ENCODING_PROPERTIES_ERROR       11
/** an error occured during compression (XXX: be more specific) */
#define ELZMA_E_COMPRESS_ERROR                  12
/** currently unsupported lzma file format was specified*/
#define ELZMA_E_UNSUPPORTED_FORMAT              13
/** an error occured when reading input */
#define ELZMA_E_INPUT_ERROR                     14
/** an error occured when writing output */
#define ELZMA_E_OUTPUT_ERROR                    15
/** LZMA header couldn't be parsed */
#define ELZMA_E_CORRUPT_HEADER                  16
/** an error occured during decompression (XXX: be more specific) */
#define ELZMA_E_DECOMPRESS_ERROR                17
/** the input stream returns EOF before the decompression could complete */
#define ELZMA_E_INSUFFICIENT_INPUT              18
/** for formats which have an emebedded crc, this error would indicated that
 *  what came out was not what went in, i.e. data corruption */
#define ELZMA_E_CRC32_MISMATCH                  19
/** for formats which have an emebedded uncompressed content length,
 *  this error indicates that the amount we read was not what we expected */
#define ELZMA_E_SIZE_MISMATCH                   20


/** Supported file formats */
typedef enum {
    ELZMA_lzip, /**< the lzip format which includes a magic number and
                 *   CRC check */
    ELZMA_lzma  /**< the LZMA-Alone format, originally designed by
                 *   Igor Pavlov and in widespread use due to lzmautils,
                 *   lacking both aforementioned features of lzip */
/* XXX: future, potentially   ,
    ELZMA_xz 
*/
} elzma_file_format;

/**
 * A callback invoked during elzma_[de]compress_run when the [de]compression
 * process has generated [de]compressed output.
 *
 * the size parameter indicates how much data is in buf to be written.
 * it is required that the write callback consume all data, and a return
 * value not equal to input size indicates and error.
 */
typedef size_t (*elzma_write_callback)(void *ctx, const void *buf,
                                       size_t size);

/**
 * A callback invoked during elzma_[de]compress_run when the [de]compression
 * process requires more [un]compressed input.
 *
 * the size parameter is an in/out argument.  on input it indicates
 * the buffer size.  on output it indicates the amount of data read into
 * buf.  when *size is zero on output it indicates EOF.
 *
 * \returns the read callback should return nonzero on failure.
 */
typedef int (*elzma_read_callback)(void *ctx, void *buf,
                                   size_t *size);

/**
 * A callback invoked during elzma_[de]compress_run to report progress
 * on the [de]compression.
 *
 * \returns the read callback should return nonzero on failure.
 */
typedef void (*elzma_progress_callback)(void *ctx, size_t complete,
                                        size_t total);


/** pointer to a malloc function, supporting client overriding memory
 *  allocation routines */
typedef void * (*elzma_malloc)(void *ctx, unsigned int sz);

/** pointer to a free function, supporting client overriding memory
 *  allocation routines */
typedef void (*elzma_free)(void *ctx, void * ptr);


/*
 * Written in 2009 by Lloyd Hilaiel
 *
 * License
 * 
 * All the cruft you find here is public domain.  You don't have to credit
 * anyone to use this code, but my personal request is that you mention
 * Igor Pavlov for his hard, high quality work.
 *
 * simple.h - a wrapper around easylzma to compress/decompress to memory 
 */

/*
 * Written in 2009 by Lloyd Hilaiel
 *
 * License
 * 
 * All the cruft you find here is public domain.  You don't have to credit
 * anyone to use this code, but my personal request is that you mention
 * Igor Pavlov for his hard, high quality work.
 *
 * easylzma/decompress.h - The API for LZMA decompression using easylzma
 */

/** an opaque handle to an lzma decompressor */
typedef struct _elzma_decompress_handle * elzma_decompress_handle;

/**
 * Allocate a handle to an LZMA decompressor object.
 */ 
elzma_decompress_handle EASYLZMA_API elzma_decompress_alloc();

/**
 * set allocation routines (optional, if not called malloc & free will
 * be used) 
 */ 
void EASYLZMA_API elzma_decompress_set_allocation_callbacks(
    elzma_decompress_handle hand,
    elzma_malloc mallocFunc, void * mallocFuncContext,
    elzma_free freeFunc, void * freeFuncContext);

/**
 * Free all data associated with an LZMA decompressor object.
 */ 
void EASYLZMA_API elzma_decompress_free(elzma_decompress_handle * hand);

/**
 * Perform decompression
 *
 * XXX: should the library automatically detect format by reading stream?
 *      currently it's based on data external to stream (such as extension
 *      or convention)
 */ 
int EASYLZMA_API elzma_decompress_run(
    elzma_decompress_handle hand,
    elzma_read_callback inputStream, void * inputContext,
    elzma_write_callback outputStream, void * outputContext,
    elzma_file_format format);

#ifdef __cplusplus
};
#endif
""".}
# Compile all easylzma files
{.compile: ("easylzma/src/*.c", "$#.obj")}
{.compile: ("easylzma/src/easylzma/*.c", "$#.obj")}
{.compile: ("easylzma/src/pavlov/*.c", "$#.obj")}

type
  elzma_file_format = enum
    ELZMA_lzip
    ELZMA_lzma

{.push importc, cdecl.}

proc free*(s: cstring) {.importc: "free", header: "<stdlib.h>".}

proc simpleCompress(format: elzma_file_format; inData: ptr cuchar; inLen: csize_t;
                    outData: ptr ptr cuchar; outLen: ptr csize_t): cint
        
proc simpleDecompress(format: elzma_file_format; inData: ptr cuchar; inLen: csize_t;
                      outData: ptr ptr cuchar; outLen: ptr csize_t): cint
{.pop.}

proc decompress*(data: string): string = 
  let inData = cast[ptr cuchar](cstring(data))
  let inLen = csize_t len(data)
  var outData: ptr cuchar
  var outLen: csize_t
  let errorCode = simpleDecompress(ELZMA_lzma, inData, inLen, 
                                   addr outData, addr outLen)
  if errorCode != 0:
    raise newException(ValueError, "LZMA decompression error - " & $errorCode)

  result = $cast[cstring](outData)
  # Free the memory allocated for output string in C library
  free(cast[cstring](outData))