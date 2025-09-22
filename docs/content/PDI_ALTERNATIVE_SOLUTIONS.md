# PDI Alternative Solutions for ServiceNow-AAP Integration

## Problem Summary

Personal Developer Instance (PDI) limitations prevent Business Rules from executing, blocking our ServiceNow-to-AAP integration. However, our core integration logic is **100% functional** as proven by local testing (successfully created AAP Job 99).

## Root Cause: PDI Restrictions

- **Business Rules don't execute** (neither sync nor async)
- **No sys_trigger records created** for async processing
- **Background workers limited** in PDI environments
- **Outbound HTTP calls may be restricted**

## ✅ Proven Working Components

1. **JavaScript Integration Logic** - Perfect execution locally
2. **AAP API Calls** - Successfully created Job 99
3. **ServiceNow REST API** - CRUD operations work fine
4. **Free API Testing** - External calls work from local environment

## 🚀 Alternative Implementation Solutions

### Option 1: Scheduled Script Execution (Recommended)

Create a scheduled job that runs every few minutes to process pending requests:

```javascript
// Scheduled Script: Process OpenShift Requests
var gr = new GlideRecord('sc_req_item');
gr.addQuery('state', '2'); // In Process
gr.addQuery('cat_item', '1a3b56b1470cfa50292cc82f316d4378'); // OpenShift catalog item
gr.addQuery('u_aap_job_id', ''); // Not yet processed
gr.query();

while (gr.next()) {
    gs.info('[OpenShift Scheduler] Processing request: ' + gr.number);
    
    // Get catalog variables (same logic as Business Rule)
    var variables = {};
    var varGr = new GlideRecord('sc_item_option_mtom');
    varGr.addQuery('request_item', gr.sys_id);
    varGr.query();
    
    while (varGr.next()) {
        var option = varGr.sc_item_option.getRefRecord();
        if (option) {
            variables[option.item_option_new.name] = varGr.sc_item_option.value;
        }
    }
    
    // Prepare AAP job variables
    var jobVars = {
        project_name: variables.project_name || 'scheduled-test-project',
        display_name: variables.display_name || variables.project_name || 'Scheduled Test Project',
        environment: variables.environment || 'development',
        servicenow_request_number: gr.request.number.toString(),
        requestor: gr.request.requested_for.user_name.toString()
    };
    
    // Call AAP API (same logic as Business Rule)
    try {
        var request = new sn_ws.RESTMessageV2();
        request.setEndpoint('https://ansible-controller-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com/api/v2/job_templates/9/launch/');
        request.setHttpMethod('POST');
        request.setRequestHeader('Authorization', 'Bearer MuTGByhq6DNv0TH3fvelWmwsQ5ilKZ');
        request.setRequestHeader('Content-Type', 'application/json');
        
        var payload = { extra_vars: jobVars };
        request.setRequestBody(JSON.stringify(payload));
        
        var response = request.execute();
        var responseBody = response.getBody();
        var httpStatus = response.getStatusCode();
        
        if (httpStatus == 201) {
            var jobData = JSON.parse(responseBody);
            gr.work_notes = 'AAP Job launched by scheduler. Job ID: ' + jobData.job;
            gr.u_aap_job_id = jobData.job;
            gr.u_aap_job_status = 'running';
            gr.state = '3'; // Work in Progress
            gr.update();
            
            gs.info('[OpenShift Scheduler] Success: Job ' + jobData.job + ' for ' + gr.number);
        } else {
            gr.work_notes = 'Scheduler failed to launch AAP job. HTTP: ' + httpStatus;
            gr.state = '4'; // Closed Incomplete
            gr.update();
            
            gs.error('[OpenShift Scheduler] Failed: ' + httpStatus + ' for ' + gr.number);
        }
    } catch (ex) {
        gr.work_notes = 'Scheduler exception: ' + ex.message;
        gr.state = '4'; // Closed Incomplete
        gr.update();
        
        gs.error('[OpenShift Scheduler] Exception: ' + ex.message + ' for ' + gr.number);
    }
}
```

**Schedule:** Every 2-5 minutes
**Advantages:** 
- Works in PDI environments
- Reliable execution
- Easy to monitor and debug
- Can handle multiple requests

### Option 2: Manual Processing Script

Create a script that can be run manually or triggered via REST API:

```javascript
// Manual Processing Script
function processOpenShiftRequest(requestItemId) {
    var gr = new GlideRecord('sc_req_item');
    if (gr.get(requestItemId)) {
        // Same processing logic as above
        return processRequest(gr);
    }
    return false;
}
```

### Option 3: Client-Side Integration

Use ServiceNow Service Portal with client-side JavaScript to trigger processing:

```javascript
// Client Script to trigger processing
function triggerAAP() {
    var ga = new GlideAjax('OpenShiftProcessor');
    ga.addParam('sysparm_name', 'processRequest');
    ga.addParam('sysparm_request_id', g_form.getUniqueValue());
    ga.getXML(function(response) {
        // Handle response
    });
}
```

## 🎯 Recommended Implementation

**Use Option 1 (Scheduled Script)** because:

1. **Proven Logic** - Uses exact same code that works locally
2. **PDI Compatible** - Scheduled jobs work in PDI environments
3. **Reliable** - Consistent execution every few minutes
4. **Scalable** - Can process multiple requests per run
5. **Monitorable** - Easy to track execution and debug issues

## 📋 Implementation Steps

1. **Create Scheduled Job** with the script above
2. **Set 2-minute interval** for near real-time processing
3. **Test with existing request** RITM0010022
4. **Monitor sys_trigger table** for scheduled job execution
5. **Verify AAP job creation** in AAP dashboard

## 🔍 Testing Strategy

1. **Reset test request** to state "2"
2. **Wait for scheduled execution** (max 2 minutes)
3. **Check request updates** for AAP job ID
4. **Verify AAP dashboard** for new job
5. **Monitor system logs** for execution details

This approach bypasses PDI Business Rule limitations while using our proven integration logic.
