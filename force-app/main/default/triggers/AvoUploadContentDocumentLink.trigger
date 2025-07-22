trigger AvoUploadContentDocumentLink on ContentDocumentLink (before insert) {
    new AvoUploadContentDocumentLinkHandler().run();
}