Здесь должно быть актуальное дерево проекта

PS C:\Vinny\Project\Flutter Projects\finance_app> tree lib /F
Структура папок тома Windows
Серийный номер тома: 00000140 54E3:3F95
C:\VINNY\PROJECT\FLUTTER PROJECTS\FINANCE_APP\LIB
│   main.dart
│   secrets.dart
│   
├───core
│   ├───debug
│   │       debug_logger.dart
│   │       log_entry.dart
│   │       
│   ├───preferences
│   │       app_settings.dart
│   │       color_settings_notifier.dart
│   │       
│   ├───theme
│   │       app_colors.dart
│   │       app_dimensions.dart
│   │       app_icons.dart
│   │       app_text_styles.dart
│   │       app_theme.dart
│   │       theme_notifier.dart
│   │       
│   ├───utils
│   │       account_name_utils.dart
│   │       custom_page_scroll_physics.dart
│   │       date_utils.dart
│   │       
│   └───widgets
├───data
│   ├───database
│   │       database_helper.dart
│   │       memory_database.dart
│   │       
│   ├───repositories
│   │       account_repository.dart
│   │       card_color_settings_repository.dart
│   │       operation_repository.dart
│   │       receipt_repository.dart
│   │       transfer_repository.dart
│   │       
│   └───services
│       │   category_service.dart
│       │   data_normalizer_service.dart.dart
│       │   openrouter_service.dart
│       │   photo_cleanup_service.dart
│       │   photo_storage_service.dart
│       │   receipt_creation_service.dart
│       │   
│       └───background_manager
│           │   background_task.dart
│           │   background_task_manager.dart
│           │   
│           └───widgets
│                   task_monitor_floating.dart
│                   
├───domain
│   ├───entities
│   │       financial_state.dart
│   │       transfer.dart
│   │       
│   └───usecases
│           financial_calculator.dart
│           financial_service.dart
│           operation_service.dart
│           transfer_service.dart
│           
├───features
│   ├───accounts
│   │   │   accounts_screen.dart
│   │   │   account_details_screen.dart
│   │   │   
│   │   └───widgets
│   │           account_card.dart
│   │           create_account_dialog.dart
│   │           select_account_dialog.dart
│   │           
│   ├───ai
│   │       ai_key_manager.dart
│   │       ai_limit_exception.dart
│   │       ai_profile.dart
│   │       ai_profiles.dart
│   │       
│   ├───debug
│   │   ├───screens
│   │   │       debug_log_screen.dart
│   │   │       
│   │   └───widgets
│   │           log_filter_chips.dart
│   │           log_tile.dart
│   │           
│   ├───home
│   │   │   home_screen.dart
│   │   │   
│   │   └───widgets
│   │           accounts_carousel.dart
│   │           home_app_bar.dart
│   │           home_overview.dart
│   │           operation_history_list.dart
│   │           receipt_floating_button.dart
│   │           
│   ├───memory
│   │   ├───diagnostics
│   │   │   │   diagnostic_check.dart
│   │   │   │   diagnostic_error.dart
│   │   │   │   diagnostic_metrics.dart
│   │   │   │   diagnostic_report.dart
│   │   │   │   diagnostic_result.dart
│   │   │   │   diagnostic_severity.dart
│   │   │   │   diagnostic_version.dart
│   │   │   │   memory_diagnostic_service.dart
│   │   │   │   
│   │   │   ├───calculators
│   │   │   │       health_score_calculator.dart
│   │   │   │       
│   │   │   ├───checks
│   │   │   │       chunking_check.dart
│   │   │   │       connection_check.dart
│   │   │   │       count_check.dart
│   │   │   │       dimension_check.dart
│   │   │   │       duplicate_check.dart
│   │   │   │       embedding_api_check.dart
│   │   │   │       empty_vector_check.dart
│   │   │   │       invalid_vector_check.dart
│   │   │   │       performance_check.dart
│   │   │   │       search_diagnostic_check.dart
│   │   │   │       search_quality_check.dart
│   │   │   │       similarity_check.dart
│   │   │   │       stale_check.dart
│   │   │   │       
│   │   │   ├───generators
│   │   │   │       markdown_report_generator.dart
│   │   │   │       
│   │   │   ├───test_cases
│   │   │   │       search_test_cases.dart
│   │   │   │       
│   │   │   └───widgets
│   │   │           diagnostic_button.dart
│   │   │           diagnostic_dialog.dart
│   │   │           
│   │   ├───models
│   │   │       embedding_model.dart
│   │   │       indexing_state.dart
│   │   │       memory_chunk.dart
│   │   │       memory_note.dart
│   │   │       memory_search_result.dart
│   │   │       memory_source.dart
│   │   │       obsidian_note.dart
│   │   │       
│   │   ├───providers
│   │   ├───repositories
│   │   │       embedding_repository.dart
│   │   │       indexing_state_repository.dart
│   │   │       markdown_repository.dart
│   │   │       memory_note_repository.dart
│   │   │       memory_repository.dart
│   │   │       
│   │   ├───screens
│   │   │       memory_screen.dart
│   │   │       
│   │   ├───services
│   │   │       chunking_service.dart
│   │   │       embedding_service.dart
│   │   │       indexing_queue.dart
│   │   │       indexing_service.dart
│   │   │       markdown_chunk_parser.dart
│   │   │       memory_migration_service.dart
│   │   │       obsidian_reader_service.dart
│   │   │       semantic_search_service.dart
│   │   │       sqlite_vector_search_service.dart
│   │   │       sqlite_vec_search_service.dart
│   │   │       vector_search_service.dart
│   │   │       vector_similarity_service.dart
│   │   │       
│   │   ├───utils
│   │   │       embedding_utils.dart
│   │   │       markdown_utils.dart
│   │   │       vector_utils.dart
│   │   │       
│   │   └───widgets
│   │           indexing_progress.dart
│   │           search_bar.dart
│   │           search_result_tile.dart
│   │           
│   ├───navigation
│   │       main_navigation.dart
│   │       
│   ├───operations
│   │   │   add_operation_screen.dart
│   │   │   operations_screen.dart
│   │   │   operation_details_screen.dart
│   │   │   
│   │   └───widgets
│   │           operation_tile.dart
│   │           undo_delete_panel.dart
│   │           
│   ├───receipts
│   │       edit_receipt_item_screen.dart
│   │       edit_receipt_screen.dart
│   │       receipts_screen.dart
│   │       receipt_details_screen.dart
│   │       
│   ├───settings
│   │       card_colors_settings_screen.dart
│   │       settings_screen.dart
│   │       
│   ├───transfers
│   │   └───screens
│   │           transfer_screen.dart
│   │           
│   └───widgets
└───models
        account.dart
        card_color_settings.dart
        category.dart
        operation.dart
        operation_type.dart
        parsed_receipt.dart
        receipt.dart
        receipt_item.dart
        receipt_result.dart
        