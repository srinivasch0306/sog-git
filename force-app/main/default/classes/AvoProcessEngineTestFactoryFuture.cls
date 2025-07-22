public class AvoProcessEngineTestFactoryFuture {
    @future
    public static void SetUpEmailTemplate(String name, string subject, String htmlValue) {

        EmailTemplate entity = new EmailTemplate(
            Name = name,
            Subject = subject,
            HtmlValue = htmlValue
        );

        insert entity;
    }
}