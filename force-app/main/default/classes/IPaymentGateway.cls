public Interface IPaymentGateway
{
    Boolean authenticate(String accountId);
    String refund(String accountId, String transactionId, Decimal amount);
    String void(String accountId, String transactionId, Decimal amount);
    String getSessionKey(Decimal amount);
}