trigger AVOLocLetterGeneration on ContentDocumentLink (after insert) {
    new AVOLocLetterGenerationHandler().run();
}