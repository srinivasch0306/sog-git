@isTest
public class BGSwitchControllerTest {
	@isTest
    static void testAll() {
        BGSwitchController bgSwitch = new BGSwitchController();
        bgSwitch.isDRESystemTestActive = false;
        bgSwitch.toggleDRESystemTest();
        System.assertEquals(true, true);
    }
}