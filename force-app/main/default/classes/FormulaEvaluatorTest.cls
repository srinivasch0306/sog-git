@IsTest
public class FormulaEvaluatorTest {
	@IsTest
    private static void TestFormulaEvaluatedCorrectly(){
        FormulaEvaluator evaluator = new FormulaEvaluator();
        Map<String, Object> mergeList = new Map<String, Object>();
        Object result = evaluator.evaluateFormula('ADD(1,2)', mergeList);
        Integer actualResult = Integer.valueOf(result);
        System.assertEquals(3, actualResult);
    }
}