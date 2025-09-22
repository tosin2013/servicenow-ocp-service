#!/usr/bin/env node

/**
 * Local Test Script for ServiceNow Business Rule Logic
 * Tests the AAP REST API call logic before deploying to ServiceNow
 */

const https = require('https');

// Mock ServiceNow current object (simulates RITM0010022)
const mockCurrent = {
    sys_id: '88d79d82478c3e50292cc82f316d43dc',
    number: 'RITM0010022',
    state: '2',
    cat_item: {
        value: '1a3b56b1470cfa50292cc82f316d4378'
    },
    request: {
        number: 'REQ0010051',
        requested_for: {
            user_name: 'admin'
        }
    }
};

// Mock catalog variables (what we expect from ServiceNow)
const mockVariables = {
    project_name: 'e2e-test-project',
    display_name: 'E2E Test Project',
    environment: 'development',
    requestor_first_name: 'E2E',
    requestor_last_name: 'Tester',
    team_members: 'e2e-test-team',
    business_justification: 'End-to-end integration testing'
};

// AAP Configuration
const AAP_CONFIG = {
    url: 'https://ansible-controller-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com',
    token: 'REPLACE_WITH_ACTUAL_TOKEN' // TODO: Use secure token,
    jobTemplateId: '9'
};

/**
 * Mock ServiceNow gs.info function
 */
function gsInfo(message) {
    console.log(`[ServiceNow INFO] ${message}`);
}

/**
 * Mock ServiceNow gs.error function
 */
function gsError(message) {
    console.error(`[ServiceNow ERROR] ${message}`);
}

/**
 * Test a free external API first to verify REST calls work
 */
function testFreeApiCall() {
    console.log('🌐 Testing Free External API Call First...\n');

    // Test with JSONPlaceholder - a free testing API
    const options = {
        hostname: 'jsonplaceholder.typicode.com',
        port: 443,
        path: '/posts/1',
        method: 'GET',
        headers: {
            'User-Agent': 'ServiceNow-Test-Agent/1.0'
        }
    };

    console.log('🚀 Making free API call...');
    console.log(`URL: https://${options.hostname}${options.path}`);
    console.log(`Method: ${options.method}\n`);

    const req = https.request(options, (res) => {
        let responseBody = '';

        res.on('data', (chunk) => {
            responseBody += chunk;
        });

        res.on('end', () => {
            console.log(`📊 Free API Response:`);
            console.log(`Status Code: ${res.statusCode}`);
            console.log(`Body: ${responseBody}\n`);

            if (res.statusCode === 200) {
                console.log('✅ SUCCESS: Free API call works!');
                console.log('🔄 Now testing AAP API call...\n');

                // If free API works, test AAP API
                testBusinessRuleLogic();
            } else {
                console.error('❌ Free API call failed - network/HTTPS issues');
                gsError(`Free API test failed with status: ${res.statusCode}`);
            }
        });
    });

    req.on('error', (error) => {
        console.error('❌ Free API request error:', error.message);
        console.error('🚨 This indicates network/HTTPS connectivity issues');
        gsError(`Free API test error: ${error.message}`);
    });

    req.end();
}

/**
 * Test the Business Rule logic locally
 */
function testBusinessRuleLogic() {
    console.log('🧪 Testing Business Rule Logic Locally\n');

    // Step 1: Validate state
    console.log('Step 1: Validating state...');
    if (mockCurrent.state !== '2') {
        console.log('❌ State check failed - exiting');
        return;
    }
    console.log('✅ State is "2" (In Process) - continuing\n');

    // Step 2: Log trigger
    gsInfo(`Business Rule triggered for request: ${mockCurrent.request.number}`);

    // Step 3: Prepare job variables
    console.log('Step 2: Preparing AAP job variables...');
    const jobVars = {
        project_name: mockVariables.project_name || 'e2e-test-project',
        display_name: mockVariables.display_name || mockVariables.project_name || 'E2E Test Project',
        environment: mockVariables.environment || 'development',
        requestor_first_name: mockVariables.requestor_first_name || 'E2E',
        requestor_last_name: mockVariables.requestor_last_name || 'Tester',
        team_members: mockVariables.team_members || 'e2e-test-team',
        business_justification: mockVariables.business_justification || 'End-to-end integration testing',
        servicenow_request_number: mockCurrent.request.number,
        requestor: mockCurrent.request.requested_for.user_name
    };

    console.log('✅ Job variables prepared:');
    console.log(JSON.stringify(jobVars, null, 2));

    gsInfo(`Launching AAP job for project: ${jobVars.project_name}`);

    // Step 4: Test AAP API call
    console.log('\nStep 3: Testing AAP API call...');
    testAAPApiCall(jobVars);
}

/**
 * Test the actual AAP API call
 */
function testAAPApiCall(jobVars) {
    const payload = {
        extra_vars: jobVars
    };
    
    const postData = JSON.stringify(payload);
    
    const options = {
        hostname: 'ansible-controller-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com',
        port: 443,
        path: `/api/v2/job_templates/${AAP_CONFIG.jobTemplateId}/launch/`,
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${AAP_CONFIG.token}`,
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(postData)
        },
        // Allow self-signed certificates (like ServiceNow does)
        rejectUnauthorized: false
    };
    
    console.log('🚀 Making AAP API call...');
    console.log(`URL: ${AAP_CONFIG.url}${options.path}`);
    console.log(`Method: ${options.method}`);
    console.log(`Headers: ${JSON.stringify(options.headers, null, 2)}`);
    console.log(`Payload: ${postData}\n`);
    
    const req = https.request(options, (res) => {
        let responseBody = '';
        
        res.on('data', (chunk) => {
            responseBody += chunk;
        });
        
        res.on('end', () => {
            console.log(`📊 AAP API Response:`);
            console.log(`Status Code: ${res.statusCode}`);
            console.log(`Headers: ${JSON.stringify(res.headers, null, 2)}`);
            console.log(`Body: ${responseBody}\n`);
            
            if (res.statusCode === 201) {
                try {
                    const jobData = JSON.parse(responseBody);
                    console.log('✅ SUCCESS: AAP Job launched successfully!');
                    console.log(`Job ID: ${jobData.job}`);
                    console.log(`Job URL: ${AAP_CONFIG.url}/#/jobs/playbook/${jobData.job}`);
                    
                    gsInfo(`AAP Job launched successfully: ${jobData.job} for request: ${mockCurrent.number}`);
                    
                    // This is what would update ServiceNow
                    console.log('\n📝 ServiceNow Updates (simulated):');
                    console.log(`work_notes: "AAP Job launched successfully. Job ID: ${jobData.job}"`);
                    console.log(`u_aap_job_id: "${jobData.job}"`);
                    console.log(`u_aap_job_status: "running"`);
                    console.log(`state: "3" (Work in Progress)`);
                    
                } catch (parseError) {
                    console.error('❌ Failed to parse AAP response:', parseError.message);
                    gsError(`Failed to parse AAP response: ${parseError.message}`);
                }
            } else {
                console.error('❌ AAP API call failed');
                console.error(`HTTP Status: ${res.statusCode}`);
                console.error(`Response: ${responseBody}`);
                
                gsError(`Failed to launch AAP job for request: ${mockCurrent.number}. Status: ${res.statusCode}, Response: ${responseBody}`);
            }
        });
    });
    
    req.on('error', (error) => {
        console.error('❌ Request error:', error.message);
        gsError(`Exception launching AAP job for request: ${mockCurrent.number}. Error: ${error.message}`);
    });
    
    req.write(postData);
    req.end();
}

// Run the test - start with free API to verify connectivity
console.log('🔧 ServiceNow Business Rule Logic Test');
console.log('=====================================\n');
testFreeApiCall();
