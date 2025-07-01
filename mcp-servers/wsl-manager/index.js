#!/usr/bin/env node

/**
 * WSL Manager MCP Server
 * WSL2 Ubuntu環境の管理・テスト用MCPサーバー
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import { exec, spawn } from 'child_process';
import { promisify } from 'util';
import fs from 'fs/promises';
import path from 'path';

const execAsync = promisify(exec);

class WSLManagerServer {
  constructor() {
    this.server = new Server(
      {
        name: 'wsl-manager',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupToolHandlers();
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'create_test_wsl_instance',
            description: 'WSL2テストインスタンスを作成',
            inputSchema: {
              type: 'object',
              properties: {
                instanceName: {
                  type: 'string',
                  description: 'テストインスタンス名',
                  default: 'Ubuntu-24-04-Test'
                },
                sourceDistro: {
                  type: 'string', 
                  description: 'ソースWSLディストロ',
                  default: 'Ubuntu-24.04'
                }
              }
            }
          },
          {
            name: 'list_wsl_instances',
            description: 'WSLインスタンス一覧表示',
            inputSchema: {
              type: 'object',
              properties: {}
            }
          },
          {
            name: 'run_wsl_command',
            description: 'WSLインスタンスでコマンド実行',
            inputSchema: {
              type: 'object',
              properties: {
                instance: {
                  type: 'string',
                  description: 'WSLインスタンス名'
                },
                command: {
                  type: 'string',
                  description: '実行するコマンド'
                }
              },
              required: ['instance', 'command']
            }
          },
          {
            name: 'setup_test_environment',
            description: 'テスト環境セットアップ',
            inputSchema: {
              type: 'object',
              properties: {
                instance: {
                  type: 'string',
                  description: 'WSLインスタンス名'
                }
              },
              required: ['instance']
            }
          },
          {
            name: 'run_ubuntu_container',
            description: 'Docker内でUbuntu24.04テストコンテナ実行',
            inputSchema: {
              type: 'object',
              properties: {
                command: {
                  type: 'string',
                  description: '実行するコマンド',
                  default: 'bash'
                }
              }
            }
          }
        ]
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'create_test_wsl_instance':
            return await this.createTestWSLInstance(args);
          
          case 'list_wsl_instances':
            return await this.listWSLInstances();
          
          case 'run_wsl_command':
            return await this.runWSLCommand(args);
          
          case 'setup_test_environment':
            return await this.setupTestEnvironment(args);
          
          case 'run_ubuntu_container':
            return await this.runUbuntuContainer(args);
          
          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            {
              type: 'text',
              text: `Error: ${error.message}`
            }
          ]
        };
      }
    });
  }

  async createTestWSLInstance(args) {
    const instanceName = args.instanceName || 'Ubuntu-24-04-Test';
    const sourceDistro = args.sourceDistro || 'Ubuntu-24.04';

    try {
      // PowerShellスクリプトを実行
      const scriptPath = path.resolve('./test-new-wsl-instance.ps1');
      const command = `powershell.exe -ExecutionPolicy Bypass -File "${scriptPath}" -TestInstanceName "${instanceName}" -SourceDistro "${sourceDistro}"`;
      
      const { stdout, stderr } = await execAsync(command);
      
      return {
        content: [
          {
            type: 'text',
            text: `WSLテストインスタンス作成完了:\n${stdout}\n${stderr ? 'エラー: ' + stderr : ''}`
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `WSLインスタンス作成エラー: ${error.message}`
          }
        ]
      };
    }
  }

  async listWSLInstances() {
    try {
      const { stdout } = await execAsync('wsl --list --verbose');
      return {
        content: [
          {
            type: 'text',
            text: `WSLインスタンス一覧:\n${stdout}`
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `WSL一覧取得エラー: ${error.message}`
          }
        ]
      };
    }
  }

  async runWSLCommand(args) {
    const { instance, command } = args;
    
    try {
      const { stdout, stderr } = await execAsync(`wsl -d ${instance} -- ${command}`);
      return {
        content: [
          {
            type: 'text',
            text: `WSL実行結果 (${instance}):\n${stdout}\n${stderr ? 'エラー: ' + stderr : ''}`
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `WSLコマンド実行エラー: ${error.message}`
          }
        ]
      };
    }
  }

  async setupTestEnvironment(args) {
    const { instance } = args;
    
    const setupCommands = [
      'mkdir -p /home/root/happyquest-test',
      'apt update && apt install -y curl wget git',
      'echo "テスト環境セットアップ完了"'
    ];

    try {
      const results = [];
      for (const cmd of setupCommands) {
        const { stdout, stderr } = await execAsync(`wsl -d ${instance} -- ${cmd}`);
        results.push(`${cmd}: ${stdout}${stderr ? ' (エラー: ' + stderr + ')' : ''}`);
      }
      
      return {
        content: [
          {
            type: 'text',
            text: `テスト環境セットアップ完了:\n${results.join('\n')}`
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `テスト環境セットアップエラー: ${error.message}`
          }
        ]
      };
    }
  }

  async runUbuntuContainer(args) {
    const command = args.command || 'bash';
    
    try {
      // Docker内でUbuntu24.04テストコンテナ実行
      const dockerCmd = `docker run --rm -it -v $(pwd):/workspace ubuntu:24.04 ${command}`;
      const { stdout, stderr } = await execAsync(dockerCmd);
      
      return {
        content: [
          {
            type: 'text',
            text: `Ubuntu24.04コンテナ実行結果:\n${stdout}\n${stderr ? 'エラー: ' + stderr : ''}`
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Dockerコンテナ実行エラー: ${error.message}`
          }
        ]
      };
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('WSL Manager MCP Server running on stdio');
  }
}

const server = new WSLManagerServer();
server.run().catch(console.error);