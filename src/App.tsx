import { useState } from 'react';
import { Shield, AlertTriangle, Bug, Lock, Eye, Database, Code, FileText, GitBranch, Zap } from 'lucide-react';

interface Issue {
  id: number;
  severity: 'critical' | 'high' | 'medium' | 'low';
  category: string;
  title: string;
  description: string;
  impact: string;
  recommendation: string;
  codeExample?: string;
  location: string;
}

const issues: Issue[] = [
  {
    id: 1,
    severity: 'critical',
    category: 'Privacy & GDPR',
    title: 'Biometric Data Collection Without Consent',
    description: 'The system collects and stores biometric data (facial recognition) and emotional state information without explicit user consent mechanisms.',
    impact: 'Violates GDPR Article 9 (processing of special categories of personal data). Facial recognition data is considered biometric data and requires explicit consent. Potential legal liability, fines up to 4% of annual revenue or €20 million.',
    recommendation: 'Implement explicit consent forms before any data collection. Add privacy policy, data retention policies, and the ability for users to withdraw consent. Implement data minimization principles.',
    location: 'ai_engine.py - entire file',
  },
  {
    id: 2,
    severity: 'critical',
    category: 'Security',
    title: 'Unencrypted Sensitive Data Storage',
    description: 'Student biometric data, emotion logs, and personal information are stored in plain CSV files without any encryption.',
    impact: 'If the system is compromised, all student data including identity, emotions, and behavioral patterns are exposed. This violates data protection regulations.',
    recommendation: 'Encrypt data at rest using AES-256. Store sensitive data in a proper database with encryption. Implement access controls and audit logs.',
    location: 'emotion_log.csv, students.csv',
    codeExample: `# Current vulnerable code:
pd.DataFrame(row).to_csv(CSV_FILE, mode="a", header=False, index=False)

# Should use encryption:
from cryptography.fernet import Fernet
encrypted_data = cipher.encrypt(data.encode())`,
  },
  {
    id: 3,
    severity: 'critical',
    category: 'Security',
    title: 'No Authentication or Access Control',
    description: 'The dashboard and monitoring system have no authentication mechanism. Anyone can access student data and emotion logs.',
    impact: 'Unauthorized access to sensitive student information. Privacy breach, potential misuse of emotional and behavioral data.',
    recommendation: 'Implement proper authentication (OAuth 2.0, JWT tokens). Add role-based access control (RBAC). Use HTTPS for all communications.',
    location: 'dashboard.py, app.R',
  },
  {
    id: 4,
    severity: 'high',
    category: 'Privacy',
    title: 'Inadequate Data Retention Policy',
    description: 'Emotion logs are continuously appended without any retention policy or automatic deletion mechanism.',
    impact: 'Indefinite storage of sensitive data violates GDPR\'s storage limitation principle. Increased risk exposure over time.',
    recommendation: 'Implement automatic data deletion after a defined period (e.g., 30 days). Allow users to request data deletion. Document data retention policies.',
    location: 'ai_engine.py - CSV logging section',
    codeExample: `# Add retention policy:
def cleanup_old_data(days=30):
    cutoff_date = datetime.now() - timedelta(days=days)
    df = pd.read_csv(CSV_FILE)
    df['Time'] = pd.to_datetime(df['Time'])
    df = df[df['Time'] > cutoff_date]
    df.to_csv(CSV_FILE, index=False)`,
  },
  {
    id: 5,
    severity: 'high',
    category: 'Security',
    title: 'SQL Injection Vulnerability (Potential)',
    description: 'While using CSV files currently, if migrated to database without proper sanitization, student IDs and names could be vulnerable to injection attacks.',
    impact: 'Database compromise, unauthorized data access, data manipulation.',
    recommendation: 'Use parameterized queries, ORM frameworks, and input validation. Never concatenate user input into queries.',
    location: 'Any future database implementation',
  },
  {
    id: 6,
    severity: 'high',
    category: 'Error Handling',
    title: 'Exposed Error Messages',
    description: 'Error messages print full stack traces and system information to console, potentially exposing system architecture.',
    impact: 'Information disclosure that could help attackers understand system internals and plan attacks.',
    recommendation: 'Implement proper logging framework. Show generic error messages to users. Log detailed errors securely for administrators only.',
    location: 'ai_engine.py - multiple exception handlers',
    codeExample: `# Current vulnerable code:
except Exception as e:
    print("Recognition Error:", e)

# Should be:
except Exception as e:
    logger.error(f"Recognition failed: {type(e).__name__}")
    display_message = "Unable to process request"`,
  },
  {
    id: 7,
    severity: 'high',
    category: 'Code Quality',
    title: 'Hardcoded Sensitive Configuration',
    description: 'LECTURE_ID and other configuration values are hardcoded in the source code instead of using proper configuration management.',
    impact: 'Difficult to maintain, risk of committing sensitive values to version control, inflexible deployment.',
    recommendation: 'Use environment variables for all configuration. Use configuration files (not committed to git). Implement proper secrets management.',
    location: 'ai_engine.py - line with LECTURE_ID = "L1"',
    codeExample: `# Current:
LECTURE_ID = "L1"

# Should be:
LECTURE_ID = os.getenv("LECTURE_ID", "DEFAULT")`,
  },
  {
    id: 8,
    severity: 'medium',
    category: 'Performance',
    title: 'Inefficient Face Recognition Per Frame',
    description: 'DeepFace.find() is called on every single frame for every detected face, causing massive performance overhead.',
    impact: 'High CPU usage, slow response times, poor scalability, potential system crashes under load.',
    recommendation: 'Implement face recognition throttling (every N frames). Use face tracking to avoid re-recognizing same person. Cache recognition results.',
    location: 'ai_engine.py - main loop',
    codeExample: `# Add frame skipping:
frame_count = 0
RECOGNITION_INTERVAL = 30  # Every 30 frames

if frame_count % RECOGNITION_INTERVAL == 0:
    # Perform recognition
    identities = DeepFace.find(...)
frame_count += 1`,
  },
  {
    id: 9,
    severity: 'medium',
    category: 'Security',
    title: 'No Input Validation',
    description: 'Student IDs, names, and file paths are not validated before processing, allowing potential path traversal or injection attacks.',
    impact: 'Path traversal attacks, arbitrary file access, system compromise.',
    recommendation: 'Validate all inputs. Use allowlists for file paths. Sanitize student IDs and names. Implement proper input validation library.',
    location: 'ai_engine.py - student ID processing',
    codeExample: `# Add validation:
import re

def validate_student_id(sid):
    if not re.match(r'^\\d{1,10}$', str(sid)):
        raise ValueError("Invalid student ID")
    return int(sid)`,
  },
  {
    id: 10,
    severity: 'medium',
    category: 'Privacy',
    title: 'No Data Anonymization',
    description: 'Student identities are directly linked to emotion data without any anonymization or pseudonymization.',
    impact: 'Privacy violation, inability to share data for research, increased GDPR compliance risk.',
    recommendation: 'Use pseudonymization techniques. Separate identity from behavioral data. Implement data anonymization for analytics.',
    location: 'emotion_log.csv structure',
  },
  {
    id: 11,
    severity: 'medium',
    category: 'Reliability',
    title: 'Race Condition in CSV File Writing',
    description: 'Multiple processes could write to emotion_log.csv simultaneously without proper file locking, causing data corruption.',
    impact: 'Data loss, corrupted logs, inconsistent analytics, system instability.',
    recommendation: 'Implement file locking mechanism. Use proper database instead of CSV. Add transaction support.',
    location: 'ai_engine.py - CSV write operations',
    codeExample: `# Use file locking:
import fcntl

with open(CSV_FILE, 'a') as f:
    fcntl.flock(f, fcntl.LOCK_EX)
    df.to_csv(f, mode='a', header=False, index=False)
    fcntl.flock(f, fcntl.LOCK_UN)`,
  },
  {
    id: 12,
    severity: 'medium',
    category: 'Security',
    title: 'Insecure Default Camera Source',
    description: 'Camera source defaults to "0" and auto-detection tries multiple camera indices without authorization checks.',
    impact: 'Potential unauthorized camera access, privacy violation if wrong camera is accessed.',
    recommendation: 'Require explicit camera selection by authorized user. Add camera access permissions. Log all camera access attempts.',
    location: 'ai_engine.py - open_camera function',
  },
  {
    id: 13,
    severity: 'low',
    category: 'Code Quality',
    title: 'Missing Dependencies Documentation',
    description: 'No requirements.txt or setup documentation for Python dependencies. R dependencies not documented.',
    impact: 'Difficult deployment, version conflicts, reproducibility issues.',
    recommendation: 'Create requirements.txt with pinned versions. Document all dependencies. Use virtual environments.',
    location: 'Project root - missing files',
  },
  {
    id: 14,
    severity: 'low',
    category: 'Testing',
    title: 'No Unit Tests or Integration Tests',
    description: 'The project has no automated tests to verify functionality or catch regressions.',
    impact: 'Higher risk of bugs, difficult to refactor safely, no quality assurance.',
    recommendation: 'Implement pytest for Python code. Add unit tests for core functions. Create integration tests for end-to-end workflows.',
    location: 'Entire project',
  },
  {
    id: 15,
    severity: 'low',
    category: 'Code Quality',
    title: 'Magic Numbers Throughout Code',
    description: 'Hardcoded values like 0.6 for distance threshold, confidence calculations without explanation.',
    impact: 'Difficult to maintain and tune, unclear business logic, hard to debug.',
    recommendation: 'Define constants at top of file with meaningful names. Add comments explaining thresholds. Make values configurable.',
    location: 'ai_engine.py - various locations',
    codeExample: `# Instead of:
if best_match["distance"] > 0.6:

# Use:
RECOGNITION_DISTANCE_THRESHOLD = 0.6  # Cosine distance threshold
if best_match["distance"] > RECOGNITION_DISTANCE_THRESHOLD:`,
  },
  {
    id: 16,
    severity: 'high',
    category: 'Ethical Concerns',
    title: 'Continuous Emotion Surveillance',
    description: 'The system continuously monitors and logs student emotions, creating a surveillance environment that may impact mental health and autonomy.',
    impact: 'Psychological impact on students, potential misuse by authorities, chilling effect on classroom participation, ethical violations.',
    recommendation: 'Consider whether emotion monitoring is necessary. If required, make it opt-in, limit recording times, and ensure transparent usage policies. Consult ethics board.',
    location: 'System design - overall approach',
  },
];

function App() {
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [selectedSeverity, setSelectedSeverity] = useState<string>('all');
  const [expandedIssue, setExpandedIssue] = useState<number | null>(null);

  const categories = ['all', ...Array.from(new Set(issues.map(i => i.category)))];
  const severities = ['all', 'critical', 'high', 'medium', 'low'];

  const filteredIssues = issues.filter(issue => {
    const categoryMatch = selectedCategory === 'all' || issue.category === selectedCategory;
    const severityMatch = selectedSeverity === 'all' || issue.severity === selectedSeverity;
    return categoryMatch && severityMatch;
  });

  const severityCounts = {
    critical: issues.filter(i => i.severity === 'critical').length,
    high: issues.filter(i => i.severity === 'high').length,
    medium: issues.filter(i => i.severity === 'medium').length,
    low: issues.filter(i => i.severity === 'low').length,
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'bg-red-100 text-red-800 border-red-300';
      case 'high': return 'bg-orange-100 text-orange-800 border-orange-300';
      case 'medium': return 'bg-yellow-100 text-yellow-800 border-yellow-300';
      case 'low': return 'bg-blue-100 text-blue-800 border-blue-300';
      default: return 'bg-gray-100 text-gray-800 border-gray-300';
    }
  };

  const getSeverityIcon = (severity: string) => {
    switch (severity) {
      case 'critical': return <AlertTriangle className="w-5 h-5" />;
      case 'high': return <Shield className="w-5 h-5" />;
      case 'medium': return <Bug className="w-5 h-5" />;
      case 'low': return <FileText className="w-5 h-5" />;
      default: return <FileText className="w-5 h-5" />;
    }
  };

  const getCategoryIcon = (category: string) => {
    if (category.includes('Security')) return <Lock className="w-4 h-4" />;
    if (category.includes('Privacy')) return <Eye className="w-4 h-4" />;
    if (category.includes('Database')) return <Database className="w-4 h-4" />;
    if (category.includes('Code')) return <Code className="w-4 h-4" />;
    if (category.includes('Performance')) return <Zap className="w-4 h-4" />;
    return <GitBranch className="w-4 h-4" />;
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      {/* Header */}
      <header className="bg-gray-800 border-b border-gray-700 shadow-xl">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <Shield className="w-10 h-10 text-red-500" />
              <div>
                <h1 className="text-3xl font-bold text-white">Security Analysis Report</h1>
                <p className="text-gray-400 mt-1">AI Classroom Monitoring System</p>
              </div>
            </div>
            <div className="text-right">
              <div className="text-2xl font-bold text-red-500">{issues.length}</div>
              <div className="text-sm text-gray-400">Issues Found</div>
            </div>
          </div>
        </div>
      </header>

      {/* Stats Dashboard */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <div className="bg-red-900 bg-opacity-50 rounded-lg p-6 border-2 border-red-500">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-red-300 text-sm font-medium">Critical</div>
                <div className="text-4xl font-bold text-white mt-2">{severityCounts.critical}</div>
              </div>
              <AlertTriangle className="w-12 h-12 text-red-400" />
            </div>
          </div>
          <div className="bg-orange-900 bg-opacity-50 rounded-lg p-6 border-2 border-orange-500">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-orange-300 text-sm font-medium">High</div>
                <div className="text-4xl font-bold text-white mt-2">{severityCounts.high}</div>
              </div>
              <Shield className="w-12 h-12 text-orange-400" />
            </div>
          </div>
          <div className="bg-yellow-900 bg-opacity-50 rounded-lg p-6 border-2 border-yellow-500">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-yellow-300 text-sm font-medium">Medium</div>
                <div className="text-4xl font-bold text-white mt-2">{severityCounts.medium}</div>
              </div>
              <Bug className="w-12 h-12 text-yellow-400" />
            </div>
          </div>
          <div className="bg-blue-900 bg-opacity-50 rounded-lg p-6 border-2 border-blue-500">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-blue-300 text-sm font-medium">Low</div>
                <div className="text-4xl font-bold text-white mt-2">{severityCounts.low}</div>
              </div>
              <FileText className="w-12 h-12 text-blue-400" />
            </div>
          </div>
        </div>

        {/* Filters */}
        <div className="bg-gray-800 rounded-lg p-6 mb-8 border border-gray-700">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Filter by Category</label>
              <select
                value={selectedCategory}
                onChange={(e) => setSelectedCategory(e.target.value)}
                className="w-full bg-gray-700 border border-gray-600 text-white rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {categories.map(cat => (
                  <option key={cat} value={cat}>{cat === 'all' ? 'All Categories' : cat}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Filter by Severity</label>
              <select
                value={selectedSeverity}
                onChange={(e) => setSelectedSeverity(e.target.value)}
                className="w-full bg-gray-700 border border-gray-600 text-white rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {severities.map(sev => (
                  <option key={sev} value={sev}>{sev === 'all' ? 'All Severities' : sev.charAt(0).toUpperCase() + sev.slice(1)}</option>
                ))}
              </select>
            </div>
          </div>
        </div>

        {/* Issues List */}
        <div className="space-y-4">
          {filteredIssues.map((issue) => (
            <div
              key={issue.id}
              className="bg-gray-800 rounded-lg border border-gray-700 overflow-hidden shadow-lg hover:shadow-2xl transition-shadow"
            >
              <div
                className="p-6 cursor-pointer"
                onClick={() => setExpandedIssue(expandedIssue === issue.id ? null : issue.id)}
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-3 mb-3">
                      <span className={`px-3 py-1 rounded-full text-xs font-semibold border flex items-center space-x-1 ${getSeverityColor(issue.severity)}`}>
                        {getSeverityIcon(issue.severity)}
                        <span className="ml-1">{issue.severity.toUpperCase()}</span>
                      </span>
                      <span className="flex items-center space-x-1 text-gray-400 text-sm">
                        {getCategoryIcon(issue.category)}
                        <span>{issue.category}</span>
                      </span>
                    </div>
                    <h3 className="text-xl font-semibold text-white mb-2">{issue.title}</h3>
                    <p className="text-gray-300 mb-3">{issue.description}</p>
                    <div className="text-sm text-gray-500">
                      📍 Location: <span className="text-gray-400 font-mono">{issue.location}</span>
                    </div>
                  </div>
                  <button className="ml-4 text-gray-400 hover:text-white transition-colors">
                    <svg
                      className={`w-6 h-6 transform transition-transform ${expandedIssue === issue.id ? 'rotate-180' : ''}`}
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                    </svg>
                  </button>
                </div>
              </div>

              {expandedIssue === issue.id && (
                <div className="border-t border-gray-700 bg-gray-750 p-6 space-y-4">
                  <div>
                    <h4 className="text-lg font-semibold text-red-400 mb-2">⚠️ Impact</h4>
                    <p className="text-gray-300">{issue.impact}</p>
                  </div>
                  <div>
                    <h4 className="text-lg font-semibold text-green-400 mb-2">✅ Recommendation</h4>
                    <p className="text-gray-300">{issue.recommendation}</p>
                  </div>
                  {issue.codeExample && (
                    <div>
                      <h4 className="text-lg font-semibold text-blue-400 mb-2">💻 Code Example</h4>
                      <pre className="bg-gray-900 rounded-lg p-4 overflow-x-auto">
                        <code className="text-sm text-green-300">{issue.codeExample}</code>
                      </pre>
                    </div>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>

        {filteredIssues.length === 0 && (
          <div className="bg-gray-800 rounded-lg p-12 text-center border border-gray-700">
            <Shield className="w-16 h-16 text-gray-600 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-400 mb-2">No issues found</h3>
            <p className="text-gray-500">Try adjusting your filters</p>
          </div>
        )}

        {/* Summary Section */}
        <div className="mt-12 bg-gradient-to-r from-red-900 to-orange-900 rounded-lg p-8 border-2 border-red-500">
          <h2 className="text-2xl font-bold text-white mb-4">🎯 Executive Summary</h2>
          <div className="space-y-3 text-gray-200">
            <p className="leading-relaxed">
              The AI Classroom Monitoring System has <strong>{severityCounts.critical} critical</strong> and <strong>{severityCounts.high} high-severity</strong> issues that require immediate attention. The most pressing concerns are:
            </p>
            <ul className="list-disc list-inside space-y-2 ml-4">
              <li><strong>GDPR Compliance:</strong> Collection of biometric data without consent mechanisms</li>
              <li><strong>Data Security:</strong> Unencrypted storage of sensitive student information</li>
              <li><strong>Authentication:</strong> No access control on dashboards displaying private data</li>
              <li><strong>Ethical Concerns:</strong> Continuous emotion surveillance without clear policies</li>
            </ul>
            <p className="leading-relaxed mt-4">
              <strong>Recommendation:</strong> This system should not be deployed in production until critical security and privacy issues are addressed. Consult with legal counsel regarding GDPR compliance and obtain ethics board approval before collecting student biometric data.
            </p>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="bg-gray-800 border-t border-gray-700 mt-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="text-center text-gray-400 text-sm">
            Security Analysis Generated • {new Date().toLocaleDateString()} • <a href="https://github.com/AhmedAlyasergy/AI-ClassroomTEST" target="_blank" rel="noopener noreferrer" className="text-blue-400 hover:text-blue-300">View Repository</a>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App;
