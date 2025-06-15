/**
 * ????????? ???????
 * PROJECT_RULES.md????????????
 */

const { describe, test, expect, beforeEach, afterEach, jest } = require('@jest/globals');
const fs = require('fs').promises;
const path = require('path');

// ????????????????
jest.mock('fs', () => ({
  promises: {
    writeFile: jest.fn(),
    readFile: jest.fn(),
    access: jest.fn()
  }
}));

// HTTP ?????????
const mockFetch = jest.fn();
global.fetch = mockFetch;

// ????????????????
const TEST_CONFIG = {
  monitoringInterval: 1000, // 1?????????
  maxHistoryRecords: 10,    // ??????
  responseTimeThreshold: 2000, // 2???
  reportInterval: 5000,     // 5????????????
  services: {
    'HappyQuest Main App': 'http://localhost:3000',
    'GitHub Actions': 'https://api.github.com/repos/happyquest/happyquest/actions/runs',
    'n8n Workflows': 'http://localhost:5678'
  }
};

describe('????????? - ???????', () => {
  let MonitoringDashboard;
  
  beforeEach(() => {
    jest.clearAllMocks();
    // ??????????????????
    MonitoringDashboard = require('../../monitoring/monitoring-dashboard.js');
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('????????', () => {
    test('????????????', async () => {
      // Arrange
      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve({ status: 'healthy' })
      });

      // Act
      const result = await MonitoringDashboard.checkServiceHealth('http://localhost:3000');

      // Assert
      expect(result.status).toBe('HEALTHY');
      expect(result.responseTime).toBeLessThan(TEST_CONFIG.responseTimeThreshold);
      expect(mockFetch).toHaveBeenCalledWith('http://localhost:3000');
    });

    test('?????????', async () => {
      // Arrange
      mockFetch.mockRejectedValueOnce(new Error('Connection refused'));

      // Act
      const result = await MonitoringDashboard.checkServiceHealth('http://localhost:3000');

      // Assert
      expect(result.status).toBe('UNHEALTHY');
      expect(result.error).toContain('Connection refused');
    });

    test('???????????', async () => {
      // Arrange
      mockFetch.mockImplementationOnce(() => 
        new Promise(resolve => 
          setTimeout(() => resolve({ ok: true, status: 200 }), 3000)
        )
      );

      // Act
      const result = await MonitoringDashboard.checkServiceHealth('http://localhost:3000');

      // Assert
      expect(result.status).toBe('SLOW');
      expect(result.responseTime).toBeGreaterThan(TEST_CONFIG.responseTimeThreshold);
    });
  });

  describe('????????', () => {
    test('CRITICAL ??????', () => {
      // Arrange
      const serviceStatus = {
        service: 'HappyQuest Main App',
        status: 'UNHEALTHY',
        error: 'Service completely down'
      };

      // Act
      const alert = MonitoringDashboard.generateAlert(serviceStatus);

      // Assert
      expect(alert.level).toBe('CRITICAL');
      expect(alert.message).toContain('Service completely down');
      expect(alert.autoRecover).toBe(true);
    });

    test('HIGH ???????????', () => {
      // Arrange
      const serviceStatus = {
        service: 'GitHub Actions',
        status: 'SLOW',
        responseTime: 6000
      };

      // Act
      const alert = MonitoringDashboard.generateAlert(serviceStatus);

      // Assert
      expect(alert.level).toBe('HIGH');
      expect(alert.autoRecover).toBe(true);
      expect(alert.message).toContain('Performance degradation');
    });

    test('MEDIUM/LOW ??????', () => {
      // Arrange
      const serviceStatus = {
        service: 'n8n Workflows',
        status: 'HEALTHY',
        responseTime: 3000
      };

      // Act
      const alert = MonitoringDashboard.generateAlert(serviceStatus);

      // Assert
      expect(['MEDIUM', 'LOW']).toContain(alert.level);
      expect(alert.autoRecover).toBe(false);
    });
  });

  describe('?????????', () => {
    test('????????????', async () => {
      // Arrange
      const metrics = Array.from({ length: 15 }, (_, i) => ({
        timestamp: Date.now() + i * 1000,
        service: 'Test Service',
        status: 'HEALTHY',
        responseTime: 100 + i * 10
      }));

      // Act
      for (const metric of metrics) {
        await MonitoringDashboard.recordMetrics(metric);
      }

      // Assert
      const history = MonitoringDashboard.getMetricsHistory();
      expect(history.length).toBeLessThanOrEqual(TEST_CONFIG.maxHistoryRecords);
      expect(history[0].timestamp).toBeGreaterThan(history[history.length - 1].timestamp);
    });

    test('??????????', () => {
      // Arrange
      const metrics = [
        { status: 'HEALTHY' },
        { status: 'HEALTHY' },
        { status: 'UNHEALTHY' },
        { status: 'HEALTHY' },
        { status: 'SLOW' }
      ];

      // Act
      const healthPercentage = MonitoringDashboard.calculateSystemHealth(metrics);

      // Assert
      expect(healthPercentage).toBe(60); // 3/5 = 60%
    });
  });

  describe('????????', () => {
    test('JSON ??????', async () => {
      // Arrange
      const mockMetrics = [
        { service: 'Test', status: 'HEALTHY', timestamp: Date.now() }
      ];
      fs.writeFile.mockResolvedValueOnce();

      // Act
      await MonitoringDashboard.generateJSONReport(mockMetrics);

      // Assert
      expect(fs.writeFile).toHaveBeenCalledWith(
        expect.stringContaining('monitoring-report'),
        expect.stringContaining('"systemHealth"'),
        'utf8'
      );
    });

    test('Excel ??????????', async () => {
      // Arrange
      const mockData = { systemHealth: 85, services: [] };

      // Act
      const result = await MonitoringDashboard.triggerExcelReport(mockData);

      // Assert
      expect(result.triggered).toBe(true);
      expect(result.workflow).toBe('n8n-excel-generation');
    });
  });
});

describe('????????? - ?????', () => {
  test('Playwright MCP ?????', async () => {
    // Playwright MCP??????
    const mockPlaywrightMCP = {
      navigate: jest.fn().mockResolvedValue({ success: true }),
      snapshot: jest.fn().mockResolvedValue({ elements: ['button', 'input'] }),
      click: jest.fn().mockResolvedValue({ success: true })
    };

    // Act
    const result = await MonitoringDashboard.performPlaywrightHealthCheck(mockPlaywrightMCP);

    // Assert
    expect(result.status).toBe('HEALTHY');
    expect(mockPlaywrightMCP.navigate).toHaveBeenCalled();
    expect(mockPlaywrightMCP.snapshot).toHaveBeenCalled();
  });

  test('n8n ???????????', async () => {
    // Arrange
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ 
        workflows: [{ id: '1', active: true, name: 'excel-generation' }]
      })
    });

    // Act
    const result = await MonitoringDashboard.checkN8nWorkflows();

    // Assert
    expect(result.status).toBe('HEALTHY');
    expect(result.activeWorkflows).toBeGreaterThan(0);
  });
});

describe('????????? - E2E???', () => {
  test('2??????????', async () => {
    // Arrange
    const demoConfig = { ...TEST_CONFIG, monitoringInterval: 5000 }; // 5???
    const startTime = Date.now();

    // Act
    const demoResults = await MonitoringDashboard.runDemo(demoConfig, 120000); // 2??

    // Assert
    const endTime = Date.now();
    const duration = endTime - startTime;
    
    expect(duration).toBeLessThan(125000); // 2?5???
    expect(demoResults.healthChecks).toBeGreaterThan(20); // ??20?????
    expect(demoResults.alertsGenerated).toBeGreaterThan(0);
    expect(demoResults.reportsCreated).toBeGreaterThan(0);
  });

  test('?????????', async () => {
    // Arrange
    const criticalAlert = {
      level: 'CRITICAL',
      service: 'HappyQuest Main App',
      autoRecover: true
    };

    // Act
    const recoveryResult = await MonitoringDashboard.attemptAutoRecovery(criticalAlert);

    // Assert
    expect(recoveryResult.attempted).toBe(true);
    expect(recoveryResult.success).toBeDefined();
    expect(recoveryResult.actions).toContain('service_restart');
  });
});

describe('??????', () => {
  test('PROJECT_RULES.md ????', () => {
    const compliance = MonitoringDashboard.checkProjectRulesCompliance();
    
    expect(compliance.playwrightMCPIntegration).toBe(true);
    expect(compliance.excelReportGeneration).toBe(true);
    expect(compliance.autoRecoveryMechanism).toBe(true);
    expect(compliance.qualityStandards).toBe(true);
  });

  test('???95%????', async () => {
    const testRuns = 100;
    let successCount = 0;

    for (let i = 0; i < testRuns; i++) {
      try {
        await MonitoringDashboard.performHealthCheck();
        successCount++;
      } catch (error) {
        // ????????
      }
    }

    const successRate = (successCount / testRuns) * 100;
    expect(successRate).toBeGreaterThanOrEqual(95);
  });

  test('30?????????', async () => {
    const startTime = Date.now();
    
    await MonitoringDashboard.performFullMonitoringCycle();
    
    const endTime = Date.now();
    const duration = endTime - startTime;
    
    expect(duration).toBeLessThan(30000); // 30???
  });
});

module.exports = {
  TEST_CONFIG,
  // ????????????????
  createMockServiceResponse: (status, responseTime) => ({
    ok: status === 'HEALTHY',
    status: status === 'HEALTHY' ? 200 : 500,
    json: () => Promise.resolve({ status }),
    responseTime
  })
};