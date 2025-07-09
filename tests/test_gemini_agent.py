import unittest
from unittest.mock import patch, mock_open
import os
import sys
import pytest

# Add project root to the Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from gemini_agent import execute

@pytest.fixture(autouse=True)
def set_env_vars(monkeypatch):
    monkeypatch.setenv("GOOGLE_API_KEY", "dummy_api_key")
    monkeypatch.setenv("TESTING", "true")

class TestGeminiAgent(unittest.TestCase):

    @patch('os.path.isdir')
    @patch('os.listdir')
    def test_execute_list_files_tool(self, mock_listdir, mock_isdir):
        """list_filesツールが正しく実行されるかテストする"""
        # Arrange: os.path.isdirがTrueを返し、os.listdirがダミーのファイルリストを返すように設定
        mock_isdir.return_value = True
        mock_listdir.return_value = ['file1.txt', 'file2.log']
        plan = [
            {
                "id": "step_1",
                "tool": "list_files",
                "args": {"path": "/fake/dir"},
                "description": "List files in a directory.",
                "dependencies": []
            }
        ]

        # Act: execute関数を実行
        results = execute(plan)

        # Assert: 結果を検証
        self.assertEqual(len(results), 1)
        result = results[0]
        self.assertEqual(result['status'], 'success')
        self.assertIsNone(result['error'])
        self.assertFalse(result['skipped'])
        self.assertEqual(result['output'], ['file1.txt', 'file2.log'])
        mock_isdir.assert_called_once_with("/fake/dir")
        mock_listdir.assert_called_once_with("/fake/dir")

if __name__ == '__main__':
    unittest.main()

