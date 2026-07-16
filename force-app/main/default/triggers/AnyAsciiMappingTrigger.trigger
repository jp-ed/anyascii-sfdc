/*  
 *    If the record contains a Code Point, then
 *    we attempt to set the Unicode Input Value.
 */
trigger AnyAsciiMappingTrigger on AnyAsciiMapping__c (before insert, before update) {
    for (AnyAsciiMapping__c mp : Trigger.new) {
        if (mp.CodePoint__c != null && mp.InputValue__c == null && !mp.IsBlankSpace__c) {
            Integer codePointVal = Integer.valueOf(mp.CodePoint__c);
            Boolean isSurrogate = Integer.valueOf(mp.CodePoint__c) > 65536;
            List<Integer> codePointVals = new List<Integer>();
            if (isSurrogate) {
                codePointVal -= 65536;
                Integer high = 55296 + (codePointVal >> 10);
                Integer low  = 56320 + (codePointVal & 1023);
                codePointVals.add(high);
                codePointVals.add(low);           
            } else {
                codePointVals.add(codePointVal);                
            }
            mp.InputValue__c = String.fromCharArray(codePointVals);
        }
    }
}
