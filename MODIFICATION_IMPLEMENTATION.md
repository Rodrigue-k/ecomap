# Implementation Plan: Supabase, Cloudinary, and Device ID Integration

This document outlines the phased implementation plan for migrating the application to Supabase and Cloudinary.

## Journal

- **Phase 1:** Initial setup complete. Added new dependencies and created placeholder files for Supabase and Cloudinary integration. Fixed initial test failures by adding a smoke test. Corrected the package name in `pubspec.yaml` and fixed critical analyzer errors in the new repository file. The project is now in a good state to start Phase 2.

## Phase 1: Project Setup

- [x] Run all tests to ensure the project is in a good state before starting modifications.
- [x] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [x] Run the `dart_fix` tool to clean up the code.
- [x] Run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] Run `dart_format` to make sure that the formatting is correct.
- [ ] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [ ] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
- [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [ ] After commiting the change, if an app is running, use the `hot_reload` tool to reload it.

## Phase 2: Implement Supabase and Cloudinary Services

- [ ] Implement the `SupabaseClientService` to initialize and provide the Supabase client.
- [ ] Implement a `CloudinaryService` to handle image uploads using `cloudinary_public`.
- [ ] Configure Cloudinary upload to use an unsigned preset from `.env`.
- [ ] Ensure the upload process returns a `secure_url` for storage in Supabase.
- [ ] Verify that no Cloudinary API key or secret is included in the application code.
- [ ] Implement a `DeviceService` to retrieve the unique device ID.
- [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [ ] Run the `dart_fix` tool to clean up the code.
- [ ] Run the `analyze_files` tool one more time and fix any issues.
- [ ] Run any tests to make sure they all pass.
- [ ] Run `dart_format` to make sure that the formatting is correct.
- [ ] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [ ] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
- [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [ ] After commiting the change, if an app is running, use the `hot_reload` tool to reload it.

## Phase 2.5: Implement Image Service

- [ ] Create a new `ImageService` to handle image picking, resizing, and conversion to WebP.
- [ ] The service should include a method that:
    - Picks an image using `image_picker`.
    - Reads the image data and EXIF orientation.
    - Resizes the image to a max width of 1200px if it's larger, maintaining aspect ratio.
    - Encodes the image to WebP format with quality 85.
    - Saves the converted image to a temporary file.
    - Returns the temporary file path.
- [ ] Implement a progress indicator with the message "Compression en cours..." while the image is being processed.
- [ ] Create/modify unit tests for the `ImageService`.
- [ ] Run the `dart_fix` tool to clean up the code.
- [ ] Run the `analyze_files` tool one more time and fix any issues.
- [ ] Run any tests to make sure they all pass.
- [ ] Run `dart_format` to make sure that the formatting is correct.
- [ ] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [ ] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
- [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [ ] After commiting the change, if an app is running, use the `hot_reload` tool to reload it.

## Phase 3: Implement WasteBin Repository and Update UI

- [ ] Implement the `WasteBinRepository` to perform CRUD operations on the `waste_bins` table.
- [ ] Update the UI to use the `WasteBinRepository` to fetch and display waste bin data.
- [ ] Update the "add bin" functionality to use the `ImageService` and `CloudinaryService` (with `cloudinary_public`), and `WasteBinRepository`.
- [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [ ] Run the `dart_fix` tool to clean up the code.
- [ ] Run the `analyze_files` tool one more time and fix any issues.
- [ ] Run any tests to make sure they all pass.
- [ ] Run `dart_format` to make sure that the formatting is correct.
- [ ] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [ ] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
- [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [ ] After commiting the change, if an app is running, use the `hot_reload` tool to reload it.

## Phase 4: Finalization

- [ ] Update any `README.md` file for the package with relevant information from the modification (if any).
- [ ] Update any `GEMINI.md` file in the project directory so that it still correctly describes the app, its purpose, and implementation details and the layout of the files.
- [ ] Ask the user to inspect the package (and running app, if any) and say if they are satisfied with it, or if any modifications are needed.
