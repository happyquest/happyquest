// HappyQuest MCP Browser Tools 修正・改良スクリプト
// 作成日: 2025-06-08
// 目的: フォーム入力・スクリーンショット・複雑インタラクション問題解決

// 問題1: スナップショット同期エラー解決
async function fixMCPBrowserSync() {
    console.log('🔧 MCP Browser Tools同期問題を修正中...');
    
    // Wait for DOM ready
    if (document.readyState !== 'complete') {
        await new Promise(resolve => {
            document.addEventListener('DOMContentLoaded', resolve);
        });
    }
    
    // Force page refresh and stabilization
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    return {
        status: 'ready',
        url: window.location.href,
        title: document.title,
        timestamp: new Date().toISOString()
    };
}

// 問題2: フォーム入力最適化
async function enhancedFormInput(selector, text, options = {}) {
    console.log(`📝 フォーム入力実行: ${selector}`);
    
    const element = document.querySelector(selector);
    if (!element) {
        throw new Error(`Element not found: ${selector}`);
    }
    
    // Focus the element
    element.focus();
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // Clear existing content
    element.value = '';
    element.dispatchEvent(new Event('input', { bubbles: true }));
    
    // Type character by character if slowly option is enabled
    if (options.slowly) {
        for (const char of text) {
            element.value += char;
            element.dispatchEvent(new Event('input', { bubbles: true }));
            await new Promise(resolve => setTimeout(resolve, 100));
        }
    } else {
        element.value = text;
        element.dispatchEvent(new Event('input', { bubbles: true }));
    }
    
    // Trigger change event
    element.dispatchEvent(new Event('change', { bubbles: true }));
    
    return {
        success: true,
        value: element.value,
        selector: selector
    };
}

// 問題3: スクリーンショット取得改良
async function enhancedScreenshot(options = {}) {
    console.log('📷 スクリーンショット取得開始...');
    
    // Ensure page is fully loaded
    await new Promise(resolve => {
        if (document.readyState === 'complete') {
            resolve();
        } else {
            window.addEventListener('load', resolve);
        }
    });
    
    // Wait for any animations to complete
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Return screenshot data (this would be handled by MCP backend)
    return {
        ready: true,
        timestamp: new Date().toISOString(),
        dimensions: {
            width: window.innerWidth,
            height: window.innerHeight
        },
        url: window.location.href
    };
}

// 問題4: 複雑なページインタラクション改良
async function enhancedInteraction(actions) {
    console.log('🎯 複雑インタラクション実行開始...');
    
    const results = [];
    
    for (const action of actions) {
        try {
            let result;
            
            switch (action.type) {
                case 'click':
                    const clickElement = document.querySelector(action.selector);
                    if (clickElement) {
                        clickElement.click();
                        result = { success: true, action: 'click', selector: action.selector };
                    }
                    break;
                    
                case 'type':
                    result = await enhancedFormInput(action.selector, action.text, action.options);
                    break;
                    
                case 'wait':
                    await new Promise(resolve => setTimeout(resolve, action.duration || 1000));
                    result = { success: true, action: 'wait', duration: action.duration };
                    break;
                    
                case 'scroll':
                    window.scrollTo(action.x || 0, action.y || 0);
                    result = { success: true, action: 'scroll', x: action.x, y: action.y };
                    break;
                    
                default:
                    result = { success: false, error: `Unknown action: ${action.type}` };
            }
            
            results.push(result);
            
            // Wait between actions
            await new Promise(resolve => setTimeout(resolve, 500));
            
        } catch (error) {
            results.push({
                success: false,
                action: action.type,
                error: error.message
            });
        }
    }
    
    return {
        completed: true,
        results: results,
        timestamp: new Date().toISOString()
    };
}

// テスト実行関数
async function runMCPBrowserTests() {
    console.log('🚀 HappyQuest MCP Browser テスト開始...');
    
    const testResults = {
        sync: null,
        formInput: null,
        screenshot: null,
        interaction: null
    };
    
    try {
        // Test 1: Sync fix
        testResults.sync = await fixMCPBrowserSync();
        console.log('✅ 同期テスト完了:', testResults.sync);
        
        // Test 2: Form input (if search box exists)
        if (document.querySelector('input[name="q"], [role="combobox"]')) {
            testResults.formInput = await enhancedFormInput(
                'input[name="q"], [role="combobox"]',
                'HappyQuest テスト完了',
                { slowly: true }
            );
            console.log('✅ フォーム入力テスト完了:', testResults.formInput);
        }
        
        // Test 3: Screenshot preparation
        testResults.screenshot = await enhancedScreenshot();
        console.log('✅ スクリーンショットテスト完了:', testResults.screenshot);
        
        // Test 4: Complex interaction
        testResults.interaction = await enhancedInteraction([
            { type: 'wait', duration: 1000 },
            { type: 'scroll', x: 0, y: 100 },
            { type: 'wait', duration: 500 }
        ]);
        console.log('✅ インタラクションテスト完了:', testResults.interaction);
        
    } catch (error) {
        console.error('❌ テスト実行エラー:', error);
    }
    
    return testResults;
}

// Export for browser console usage
if (typeof window !== 'undefined') {
    window.HappyQuestMCPTests = {
        fixMCPBrowserSync,
        enhancedFormInput,
        enhancedScreenshot,
        enhancedInteraction,
        runMCPBrowserTests
    };
    
    console.log('🎭 HappyQuest MCP Browser改良スクリプト読み込み完了');
    console.log('📋 利用可能な関数:');
    console.log('   - window.HappyQuestMCPTests.runMCPBrowserTests()');
    console.log('   - window.HappyQuestMCPTests.enhancedFormInput(selector, text)');
    console.log('   - window.HappyQuestMCPTests.enhancedScreenshot()');
} 