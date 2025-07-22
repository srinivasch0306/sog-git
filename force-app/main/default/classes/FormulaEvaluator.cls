global class FormulaEvaluator implements MUSW.IFormulaEvaluator {
    
    global FormulaEvaluator(){
        System.debug('constructor');
    }
    global Object evaluateFormula(String formula, Map<String, Object> mergeList){
        System.debug('===test test formula is triggered==: ' + formula);
        System.debug('===merge list is ==: ' + mergeList);
        Object result;
        DRE.DREFormulaService formulaService = new DRE.DREFormulaService();
        result = formulaService.evaluateFormula(formula, mergeList);
        System.debug('===result list is ==: ' + result);
        return result;
    }
}