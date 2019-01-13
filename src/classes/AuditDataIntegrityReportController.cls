/*
    Description: Controller is created to display report File Archive and Audit Integrity report. 
                 It's has two parts:
                 1) Shows discrepancies between audit info for Root/intermediate records and File Archive records
                 2) Shows missing Root/Inter certs entries in File Archive object
    Create Date: 3/21/2018
    Updates    :
*/
public with sharing class AuditDataIntegrityReportController {
    
    //list that has audit integrity report
    public List<WrapperAccounts> lstWrapperAccounts {get; set;}
    //list that has missing root and inter certs which have missing archives
    public List<WrapperInnerAccount> lstWrapAccountMissingArchive {get; set;}
    
    //controller
    public AuditDataIntegrityReportController(){
        lstWrapperAccounts = new List<WrapperAccounts>();
        lstWrapAccountMissingArchive = new List<WrapperInnerAccount>();
        
        String rootCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeId();
        String intermediateCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        
        //query all root and inter certs and fill map (key as audit url and value as account)
        map<string, List<Account>> mapAuditURLWiseAccounts = new map<string, List<Account>>();
        for(Account objAcc: [select Id,Name,ParentId,Standard_Audit__c, Standard_Audit_Statement_Date__c ,Standard_Audit_Period_Start_Date__c ,Standard_Audit_Period_End_Date__c ,
                            BR_Audit__c, BR_Audit_Statement_Date__c,BR_Audit_Period_Start_Date__c,BR_Audit_Period_End_Date__c,EV_Audit__c ,EV_Audit_Statement_Date__c,
                            EV_Audit_Period_Start_Date__c,EV_Audit_Period_End_Date__c,EV_Code_Signing_Audit__c,EV_Code_Signing_Audit_Statement_Date__c,EV_Code_Signing_Audit_Period_Start_Date__c,
                            EV_Code_Signing_Audit_Period_End_Date__c from Account Where RecordTypeId =: rootCertRecordTypeId or RecordTypeId =: intermediateCertRecordTypeId]){
            set<string> setofAuditURLs = new set<string>();
            if(objAcc.Standard_Audit__c != null) {
                setofAuditURLs.add(objAcc.Standard_Audit__c);
            }
            if(objAcc.BR_Audit__c != null) {
                setofAuditURLs.add(objAcc.BR_Audit__c);
            }
            if(objAcc.EV_Audit__c != null) {
                setofAuditURLs.add(objAcc.EV_Audit__c);
            }
            if(objAcc.EV_Code_Signing_Audit__c != null) {
                setofAuditURLs.add(objAcc.EV_Code_Signing_Audit__c);
            }
            if(setofAuditURLs.size() > 0){
                for(string strURL: setofAuditURLs){
                    if(mapAuditURLWiseAccounts.containskey(strURL)){
                        mapAuditURLWiseAccounts.get(strURL).add(objAcc);
                    } else {
                        mapAuditURLWiseAccounts.put(strURL, new List<Account>{objAcc});
                    }
                }
            }
        }
        
        //query all file archive records and fill file archive map (key as external link and value as file archive)
        map<string, File_Archive__c> mapAuditURLWiseFileArchive = new map<string, File_Archive__c>();
        for(File_Archive__c objFA: [select Id,Name,Auditor__c,Auditor_Location__c,Audit_Statement_Date__c,
                CA_Owner__c,Document_Type__c,External_Link__c,Internal_Link__c,Period_End_Date__c,Period_Start_Date__c from File_Archive__c]){
            if(objFA.External_Link__c != null){
                mapAuditURLWiseFileArchive.put(objFA.External_Link__c, objFA);
            }
        }
        
        //fill list of missing archives for root and inter certs
        if(mapAuditURLWiseAccounts.size() > 0){
            for(string strAuditURL: mapAuditURLWiseAccounts.keyset()){
                if(!mapAuditURLWiseFileArchive.containskey(strAuditURL)){
                    for(Account objAcc: mapAuditURLWiseAccounts.get(strAuditURL)){
                        WrapperInnerAccount objInnerWrapAcc = new WrapperInnerAccount();
                        objInnerWrapAcc.objAccount = objAcc;
                        List<WrapperAccountAuditDetail> lstWrapperAccountAuditDetail = new List<WrapperAccountAuditDetail>(); 
                        boolean isMatch = true;
                        if(objAcc.Standard_Audit__c == strAuditURL){
                            isMatch = false;
                            WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                            objWrapAudit.AuditType = 'Standard Audit';
                            objWrapAudit.AuditURL = strAuditURL;
                            objWrapAudit.StatementDate = objAcc.Standard_Audit_Statement_Date__c;
                            objWrapAudit.PeriodStartDate = objAcc.Standard_Audit_Period_Start_Date__c;
                            objWrapAudit.PeriodEndDate = objAcc.Standard_Audit_Period_End_Date__c;
                            lstWrapperAccountAuditDetail.add(objWrapAudit);
                        }
                        if(objAcc.BR_Audit__c == strAuditURL){
                            isMatch = false;
                            WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                            objWrapAudit.AuditType = 'BR Audit';
                            objWrapAudit.AuditURL = strAuditURL;
                            objWrapAudit.StatementDate = objAcc.BR_Audit_Statement_Date__c ;
                            objWrapAudit.PeriodStartDate = objAcc.BR_Audit_Period_Start_Date__c;
                            objWrapAudit.PeriodEndDate = objAcc.BR_Audit_Period_End_Date__c;
                            lstWrapperAccountAuditDetail.add(objWrapAudit);
                        }
                        if(objAcc.EV_Audit__c == strAuditURL){
                            isMatch = false;
                            WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                            objWrapAudit.AuditType = 'EV SSL Audit';
                            objWrapAudit.AuditURL = strAuditURL;
                            objWrapAudit.StatementDate = objAcc.EV_Audit_Statement_Date__c;
                            objWrapAudit.PeriodStartDate = objAcc.EV_Audit_Period_Start_Date__c;
                            objWrapAudit.PeriodEndDate = objAcc.EV_Audit_Period_End_Date__c;
                            lstWrapperAccountAuditDetail.add(objWrapAudit);
                        }
                        if(objAcc.EV_Code_Signing_Audit__c == strAuditURL){
                            isMatch = false;
                            WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                            objWrapAudit.AuditType = 'EV Code Signing Audit';
                            objWrapAudit.AuditURL = strAuditURL;
                            objWrapAudit.StatementDate = objAcc.EV_Code_Signing_Audit_Statement_Date__c ;
                            objWrapAudit.PeriodStartDate = objAcc.EV_Code_Signing_Audit_Period_Start_Date__c;
                            objWrapAudit.PeriodEndDate = objAcc.EV_Code_Signing_Audit_Period_End_Date__c;
                            lstWrapperAccountAuditDetail.add(objWrapAudit);
                        }
                        if(!isMatch){
                            objInnerWrapAcc.lstWrapperAuditDetail = lstWrapperAccountAuditDetail;
                            lstWrapAccountMissingArchive.add(objInnerWrapAcc);
                        }
                    }
                }
            }
        }
        
        //create list of audit data integrity report
        if(mapAuditURLWiseFileArchive.size() > 0){
            for(string strAuditURL: mapAuditURLWiseFileArchive.keyset()){
                if(mapAuditURLWiseAccounts.containskey(strAuditURL)){
                    WrapperAccounts objWrapAcc = new WrapperAccounts();
                    objWrapAcc.AuditURL = strAuditURL;
                    File_Archive__c objFA = mapAuditURLWiseFileArchive.get(strAuditURL);
                    objWrapAcc.objFileArchive = objFA;
                    List<WrapperInnerAccount> lstInnerAccountWrapper = new List<WrapperInnerAccount>();
                    for(Account objAcc: mapAuditURLWiseAccounts.get(strAuditURL)){
                        WrapperInnerAccount objInnerWrapAcc = new WrapperInnerAccount();
                        objInnerWrapAcc.objAccount = objAcc;
                        List<WrapperAccountAuditDetail> lstWrapperAccountAuditDetail = new List<WrapperAccountAuditDetail>(); 
                        boolean isMatch = true;
                        if(objAcc.Standard_Audit__c == strAuditURL){
                            if(objFA.Audit_Statement_Date__c != objAcc.Standard_Audit_Statement_Date__c || 
                                    objFA.Period_Start_Date__c != objAcc.Standard_Audit_Period_Start_Date__c || 
                                    objFA.Period_End_Date__c != objAcc.Standard_Audit_Period_End_Date__c){
                                isMatch = false;
                                WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                                objWrapAudit.AuditType = 'Standard Audit';
                                objWrapAudit.AuditURL = strAuditURL;
                                objWrapAudit.StatementDate = objAcc.Standard_Audit_Statement_Date__c;
                                objWrapAudit.PeriodStartDate = objAcc.Standard_Audit_Period_Start_Date__c;
                                objWrapAudit.PeriodEndDate = objAcc.Standard_Audit_Period_End_Date__c;
                                if(objFA.Audit_Statement_Date__c != objAcc.Standard_Audit_Statement_Date__c){
                                    objWrapAudit.isDiffStatementDate = true;
                                }
                                if(objFA.Period_Start_Date__c != objAcc.Standard_Audit_Period_Start_Date__c){
                                    objWrapAudit.isDiffPeriodStartDate = true;
                                }
                                if(objFA.Period_End_Date__c != objAcc.Standard_Audit_Period_End_Date__c){
                                    objWrapAudit.isDiffPeriodEndDate = true;
                                }
                                lstWrapperAccountAuditDetail.add(objWrapAudit);
                            }
                        }
                        if(objAcc.BR_Audit__c == strAuditURL){
                            if(objFA.Audit_Statement_Date__c != objAcc.BR_Audit_Statement_Date__c || 
                                    objFA.Period_Start_Date__c != objAcc.BR_Audit_Period_Start_Date__c || 
                                    objFA.Period_End_Date__c != objAcc.BR_Audit_Period_End_Date__c ){
                                isMatch = false;
                                WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                                objWrapAudit.AuditType = 'BR Audit';
                                objWrapAudit.AuditURL = strAuditURL;
                                objWrapAudit.StatementDate = objAcc.BR_Audit_Statement_Date__c ;
                                objWrapAudit.PeriodStartDate = objAcc.BR_Audit_Period_Start_Date__c;
                                objWrapAudit.PeriodEndDate = objAcc.BR_Audit_Period_End_Date__c;
                                if(objFA.Audit_Statement_Date__c != objAcc.BR_Audit_Statement_Date__c){
                                    objWrapAudit.isDiffStatementDate = true;
                                }
                                if(objFA.Period_Start_Date__c != objAcc.BR_Audit_Period_Start_Date__c){
                                    objWrapAudit.isDiffPeriodStartDate = true;
                                }
                                if(objFA.Period_End_Date__c != objAcc.BR_Audit_Period_End_Date__c){
                                    objWrapAudit.isDiffPeriodEndDate = true;
                                }
                                lstWrapperAccountAuditDetail.add(objWrapAudit);
                            }
                        }
                        if(objAcc.EV_Audit__c == strAuditURL){
                            if(objFA.Audit_Statement_Date__c != objAcc.EV_Audit_Statement_Date__c || 
                                    objFA.Period_Start_Date__c != objAcc.EV_Audit_Period_Start_Date__c || 
                                    objFA.Period_End_Date__c != objAcc.EV_Audit_Period_End_Date__c){
                                isMatch = false;
                                WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                                objWrapAudit.AuditType = 'EV SSL Audit';
                                objWrapAudit.AuditURL = strAuditURL;
                                objWrapAudit.StatementDate = objAcc.EV_Audit_Statement_Date__c;
                                objWrapAudit.PeriodStartDate = objAcc.EV_Audit_Period_Start_Date__c;
                                objWrapAudit.PeriodEndDate = objAcc.EV_Audit_Period_End_Date__c;
                                if(objFA.Audit_Statement_Date__c != objAcc.EV_Audit_Statement_Date__c){
                                    objWrapAudit.isDiffStatementDate = true;
                                }
                                if(objFA.Period_Start_Date__c != objAcc.EV_Audit_Period_Start_Date__c){
                                    objWrapAudit.isDiffPeriodStartDate = true;
                                }
                                if(objFA.Period_End_Date__c != objAcc.EV_Audit_Period_End_Date__c){
                                    objWrapAudit.isDiffPeriodEndDate = true;
                                }
                                lstWrapperAccountAuditDetail.add(objWrapAudit);
                            }
                        }
                        if(objAcc.EV_Code_Signing_Audit__c == strAuditURL){
                            if(objFA.Audit_Statement_Date__c != objAcc.EV_Code_Signing_Audit_Statement_Date__c || 
                                    objFA.Period_Start_Date__c != objAcc.EV_Code_Signing_Audit_Period_Start_Date__c || 
                                    objFA.Period_End_Date__c != objAcc.EV_Code_Signing_Audit_Period_End_Date__c){
                                isMatch = false;
                                WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                                objWrapAudit.AuditType = 'EV Code Signing Audit';
                                objWrapAudit.AuditURL = strAuditURL;
                                objWrapAudit.StatementDate = objAcc.EV_Code_Signing_Audit_Statement_Date__c ;
                                objWrapAudit.PeriodStartDate = objAcc.EV_Code_Signing_Audit_Period_Start_Date__c;
                                objWrapAudit.PeriodEndDate = objAcc.EV_Code_Signing_Audit_Period_End_Date__c;
                                if(objFA.Audit_Statement_Date__c != objAcc.EV_Code_Signing_Audit_Statement_Date__c){
                                    objWrapAudit.isDiffStatementDate = true;
                                }
                                if(objFA.Period_Start_Date__c != objAcc.EV_Code_Signing_Audit_Period_Start_Date__c ){
                                    objWrapAudit.isDiffPeriodStartDate = true;
                                }
                                if(objFA.Period_End_Date__c != objAcc.EV_Code_Signing_Audit_Period_End_Date__c){
                                    objWrapAudit.isDiffPeriodEndDate = true;
                                }
                                lstWrapperAccountAuditDetail.add(objWrapAudit);
                            }
                        }
                        system.debug('isMatch ::: '+isMatch );
                        if(!isMatch){
                            objInnerWrapAcc.lstWrapperAuditDetail = lstWrapperAccountAuditDetail;
                            lstInnerAccountWrapper.add(objInnerWrapAcc);
                        }
                        
                    }
                    if(lstInnerAccountWrapper.size() > 0){
                        objWrapAcc.lstWrapperAccount = lstInnerAccountWrapper;
                        lstWrapperAccounts.add(objWrapAcc);
                    }
                }
            }
        }
    }
    /*
        Wrapper classes
    */
    public class WrapperAccounts {
        public string AuditURL {get; set;}
        public File_Archive__c objFileArchive {get; set;}
        public List<WrapperInnerAccount> lstWrapperAccount {get; set;}
    }
    
    public class WrapperInnerAccount {
        public Account objAccount {get; set;}
        public List<WrapperAccountAuditDetail> lstWrapperAuditDetail {get; set;}
    }
    
    public class WrapperAccountAuditDetail {
        public boolean isDiffStatementDate {get; set;}
        public boolean isDiffPeriodStartDate {get; set;}
        public boolean isDiffPeriodEndDate {get; set;}
        public string AuditURL {get; set;}
        public string AuditType {get; set;}
        public Date StatementDate {get; set;}
        public Date PeriodStartDate {get; set;}
        public Date PeriodEndDate {get; set;}
    }
}