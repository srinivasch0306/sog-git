public class AVO_SharePointFileProcessorQueue implements Queueable, Database.AllowsCallouts {
    private Integer folderIndex;
    private Integer fileIndex;

    public AVO_SharePointFileProcessorQueue(Integer folderIndex, Integer fileIndex) {
        this.folderIndex = folderIndex;
        this.fileIndex = fileIndex;
    }

    public void execute(QueueableContext context) {
        AVO_SharePointFileProcessor processor = new AVO_SharePointFileProcessor();
        processor.run(folderIndex, fileIndex);
    }
}