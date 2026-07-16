@isTest
private class AnyAsciiMappingTest {
    
    static testMethod void asciiTest() {
        AnyAsciiAction.Request req = new AnyAsciiAction.Request();
        req.inputString = 'Hello world';
        Assert.areEqual(
            req.inputString,
            AnyAsciiAction.execute(
                new List<AnyAsciiAction.Request>{req}
            )[0].outputString,
            'ASCII input value was modified.'
        );
    }

    static testMethod void blankSpaceTest() {
        // Non-breaking space is treated as 2 characters in some systems.
        AnyAsciiMapping__c mp = new AnyAsciiMapping__c(
            IsActive__c = true,
            IsBlankSpace__c = true,
            CodePoint__c = '160'
        );
        insert mp;
        AnyAsciiAction.Request req = new AnyAsciiAction.Request();
        req.inputString = '  Hello' + String.fromCharArray(new List<Integer>{160}) + 'world  ';
        List<AnyAsciiAction.Response> rs = AnyAsciiAction.execute(new List<AnyAsciiAction.Request>{req});
        Assert.areEqual(rs[0].outputString, 'Hello world');
    }

    static testMethod void emojiTest() {
        AnyAsciiMapping__c mp = new AnyAsciiMapping__c(
            IsActive__c = true,
            CodePoint__c = '129398',
            OutputValue__c = ':cold_face:'
        );
        insert mp;
        // Surrogates have been separated and code point re-calculated
        mp = [SELECT Id, CodePoint__c, InputValue__c FROM AnyAsciiMapping__c WHERE Id = :mp.Id];
        Assert.AreEqual('🥶', mp.InputValue__c, 'Trigger did not set InputValue__c to the Unicode of ' + mp.CodePoint__c);    
        AnyAsciiAction.Request req = new AnyAsciiAction.Request();
        req.inputString = '🥶 🥶';
        List<AnyAsciiAction.Response> rs = AnyAsciiAction.execute(new List<AnyAsciiAction.Request>{req});
        Assert.areEqual(rs[0].outputString, ':cold_face: :cold_face:');
    }

    static testMethod void hiddenCharTest() {
        // Zero-width space
        AnyAsciiMapping__c mp = new AnyAsciiMapping__c(
            IsActive__c = true,
            CodePoint__c = '8203'
        );
        insert mp;
        AnyAsciiAction.Request req = new AnyAsciiAction.Request();
        req.inputString = 'VP of Sales' + String.fromCharArray(new List<Integer>{8203});
        Assert.isFalse(req.inputString.isAsciiPrintable(), 'Value should contain a non-printable character.');
        List<AnyAsciiAction.Response> rs = AnyAsciiAction.execute(new List<AnyAsciiAction.Request>{req});
        Assert.areEqual(rs[0].outputString, 'VP of Sales');
    }
}
