#include "llama_wrapper.h"
#include "llama.cpp/llama.h"
#include "llama.cpp/common/common.h"
#include <string>
#include <vector>
#include <cstring>
#include <memory>

// Internal context structure
struct llama_context {
    llama_model* model;
    llama_context* ctx;
    gpt_params params;
    bool is_valid;
    
    llama_context() : model(nullptr), ctx(nullptr), is_valid(false) {
        // Initialize default parameters
        params.n_ctx = 2048;        // Context size
        params.n_batch = 512;       // Batch size
        params.n_threads = 4;       // Number of threads
        params.temp = 0.7f;         // Temperature
        params.top_p = 0.9f;        // Top-p sampling
        params.n_predict = 100;     // Max tokens to predict
    }
};

extern "C" {

llama_context* llama_init(const char* model_path) {
    if (!model_path) {
        return nullptr;
    }

    auto ctx = std::make_unique<llama_context>();
    
    try {
        // Initialize llama backend
        llama_backend_init(false);
        
        // Set model path
        ctx->params.model = std::string(model_path);
        
        // Load model
        ctx->model = llama_load_model_from_file(model_path, llama_model_default_params());
        if (!ctx->model) {
            return nullptr;
        }
        
        // Create context
        auto ctx_params = llama_context_default_params();
        ctx_params.n_ctx = ctx->params.n_ctx;
        ctx_params.n_batch = ctx->params.n_batch;
        ctx_params.n_threads = ctx->params.n_threads;
        
        ctx->ctx = llama_new_context_with_model(ctx->model, ctx_params);
        if (!ctx->ctx) {
            llama_free_model(ctx->model);
            return nullptr;
        }
        
        ctx->is_valid = true;
        return ctx.release();
        
    } catch (const std::exception& e) {
        return nullptr;
    }
}

char* llama_generate_text(llama_context* ctx, const char* prompt, int max_tokens) {
    if (!ctx || !ctx->is_valid || !prompt) {
        return nullptr;
    }
    
    try {
        // Tokenize prompt
        std::vector<llama_token> tokens;
        tokens.resize(strlen(prompt) + 1);
        int n_tokens = llama_tokenize(ctx->model, prompt, strlen(prompt), tokens.data(), tokens.size(), true, false);
        
        if (n_tokens < 0) {
            return nullptr;
        }
        tokens.resize(n_tokens);
        
        // Prepare for generation
        std::string result;
        const int max_gen_tokens = (max_tokens > 0) ? max_tokens : ctx->params.n_predict;
        
        // Evaluate prompt
        if (llama_decode(ctx->ctx, llama_batch_get_one(tokens.data(), tokens.size(), 0, 0)) != 0) {
            return nullptr;
        }
        
        // Generate tokens
        for (int i = 0; i < max_gen_tokens; ++i) {
            // Sample next token
            auto logits = llama_get_logits_ith(ctx->ctx, -1);
            auto n_vocab = llama_n_vocab(ctx->model);
            
            std::vector<llama_token_data> candidates;
            candidates.reserve(n_vocab);
            
            for (llama_token token_id = 0; token_id < n_vocab; token_id++) {
                candidates.emplace_back(llama_token_data{token_id, logits[token_id], 0.0f});
            }
            
            llama_token_data_array candidates_p = { candidates.data(), candidates.size(), false };
            
            // Apply temperature and top-p sampling
            llama_sample_temp(ctx->ctx, &candidates_p, ctx->params.temp);
            llama_sample_top_p(ctx->ctx, &candidates_p, ctx->params.top_p, 1);
            
            llama_token new_token = llama_sample_token(ctx->ctx, &candidates_p);
            
            // Check for end of generation
            if (new_token == llama_token_eos(ctx->model)) {
                break;
            }
            
            // Convert token to text
            char token_str[8];
            int token_len = llama_token_to_piece(ctx->model, new_token, token_str, sizeof(token_str));
            if (token_len > 0) {
                result.append(token_str, token_len);
            }
            
            // Prepare for next iteration
            if (llama_decode(ctx->ctx, llama_batch_get_one(&new_token, 1, tokens.size() + i, 0)) != 0) {
                break;
            }
        }
        
        // Return result
        char* output = (char*)malloc(result.length() + 1);
        strcpy(output, result.c_str());
        return output;
        
    } catch (const std::exception& e) {
        return nullptr;
    }
}

char* llama_get_model_info(llama_context* ctx) {
    if (!ctx || !ctx->is_valid) {
        return nullptr;
    }
    
    try {
        std::string info = "Model: " + ctx->params.model + "\n";
        info += "Context size: " + std::to_string(ctx->params.n_ctx) + "\n";
        info += "Batch size: " + std::to_string(ctx->params.n_batch) + "\n";
        info += "Threads: " + std::to_string(ctx->params.n_threads) + "\n";
        
        char* output = (char*)malloc(info.length() + 1);
        strcpy(output, info.c_str());
        return output;
        
    } catch (const std::exception& e) {
        return nullptr;
    }
}

int llama_is_valid(llama_context* ctx) {
    return (ctx && ctx->is_valid) ? 1 : 0;
}

void llama_free(llama_context* ctx) {
    if (ctx) {
        if (ctx->ctx) {
            llama_free(ctx->ctx);
        }
        if (ctx->model) {
            llama_free_model(ctx->model);
        }
        delete ctx;
    }
    llama_backend_free();
}

void llama_free_string(char* str) {
    if (str) {
        free(str);
    }
}

} // extern "C"