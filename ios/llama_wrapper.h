#ifndef LLAMA_WRAPPER_H
#define LLAMA_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// Opaque pointer for llama context
typedef struct llama_context llama_context;

/**
 * Initialize llama.cpp with a GGUF model file
 * @param model_path Path to the .gguf model file
 * @return Pointer to initialized context, or NULL on failure
 */
llama_context* llama_init(const char* model_path);

/**
 * Generate text using the loaded model
 * @param ctx Initialized llama context
 * @param prompt Input text prompt
 * @param max_tokens Maximum number of tokens to generate
 * @return Generated text (caller must free)
 */
char* llama_generate_text(llama_context* ctx, const char* prompt, int max_tokens);

/**
 * Get model information
 * @param ctx Initialized llama context
 * @return Model info string (caller must free)
 */
char* llama_get_model_info(llama_context* ctx);

/**
 * Check if context is valid
 * @param ctx Llama context
 * @return 1 if valid, 0 if invalid
 */
int llama_is_valid(llama_context* ctx);

/**
 * Free llama context and cleanup
 * @param ctx Llama context to free
 */
void llama_free(llama_context* ctx);

/**
 * Free a string returned by llama functions
 * @param str String to free
 */
void llama_free_string(char* str);

#ifdef __cplusplus
}
#endif

#endif // LLAMA_WRAPPER_H