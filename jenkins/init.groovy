import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import hudson.plugins.sonar.*
import hudson.plugins.sonar.model.TriggersConfig
import org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import jenkins.branch.BranchSource
import jenkins.plugins.git.GitSCMSource
import hudson.util.Secret

// The purpose of this file is to auto-configure Jenkins on first startup it is run.
// This eliminates the need for manual configuration via the web UI.
//  Auto-creates admin user (admin/admin123)
//  Auto-configures security
//  Auto-creates credentials (Docker registry + SonarQube)
//  Auto-configures SonarQube server
//  Auto-creates multibranch pipeline job
//  Disables setup wizard
//  Works end-to-end with docker-compose up 

def instance = Jenkins.getInstance()

println("=== Starting Jenkins Auto-Configuration ===")

// 1. Configure Security
println("Configuring security...")
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin123")
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()
println("✓ Security configured")

// 2. Configure Credentials
println("Configuring credentials...")
def domain = Domain.global()
def store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// Docker Registry credentials (basic for insecure registry)
def dockerCreds = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "docker-registry-credentials",
    "Docker Registry Credentials",
    "admin",
    "admin"
)
store.addCredentials(domain, dockerCreds)
println("✓ Docker registry credentials created")

// SonarQube Token (using default admin token)
def sonarToken = new StringCredentialsImpl(
    CredentialsScope.GLOBAL,
    "sonarqube-token",
    "SonarQube Token",
    Secret.fromString("squ_c8e3f6b8a9e0d2c1f4b5a6e7d8c9f0a1b2c3d4e5")
)
store.addCredentials(domain, sonarToken)
println("✓ SonarQube token created")

// 3. Configure SonarQube Server
println("Configuring SonarQube server...")
def sonarConf = instance.getDescriptor(SonarGlobalConfiguration.class)
def sonarInstallations = [
    new SonarInstallation(
        "SonarQube",
        "http://sonarqube:9000",
        "squ_c8e3f6b8a9e0d2c1f4b5a6e7d8c9f0a1b2c3d4e5",
        null,
        null,
        null,
        null,
        null,
        new TriggersConfig()
    )
] as SonarInstallation[]

sonarConf.setInstallations(sonarInstallations)
sonarConf.save()
println("✓ SonarQube server configured")

// 4. Disable setup wizard and CLI
instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
instance.getDescriptor("jenkins.CLI").get().setEnabled(false)
println("✓ Setup wizard disabled")

// 5. Set Jenkins URL
def jlc = JenkinsLocationConfiguration.get()
jlc.setUrl("http://jenkins:8080/")
jlc.save()
println("✓ Jenkins URL configured")

// 6. Configure executor count
instance.setNumExecutors(2)
println("✓ Executors configured")

// 7. Create Multibranch Pipeline Job
println("Creating multibranch pipeline job...")
try {
    def jobName = "microservice-pipeline"
    
    // Check if job already exists
    def existingJob = instance.getItemByFullName(jobName)
    if (existingJob != null) {
        println("Job already exists, skipping creation")
    } else {
        // Create new multibranch project
        def multibranchJob = instance.createProject(WorkflowMultiBranchProject.class, jobName)
        
        // Configure Git SCM source
        def gitSource = new GitSCMSource("microservice-repo")
        gitSource.setRemote("https://github.com/RivoltaAlpha/jenkins-cicd-platform.git")
        
        // Add branch source
        def branchSource = new BranchSource(gitSource)
        multibranchJob.getSourcesList().add(branchSource)
        
        // Set script path
        multibranchJob.getProjectFactory().setScriptPath("Jenkinsfile")
        
        // Save job
        multibranchJob.save()
        
        println("✓ Multibranch pipeline job '${jobName}' created")
    }
} catch (Exception e) {
    println("Warning: Could not create multibranch job: ${e.message}")
    println("Job can be created manually or will be created on first repository scan")
}

// 8. Enable Prometheus metrics
println("Enabling Prometheus metrics...")
try {
    def prometheusConfig = instance.getDescriptor("org.jenkinsci.plugins.prometheus.config.PrometheusConfiguration")
    if (prometheusConfig != null) {
        prometheusConfig.setCollectingMetricsPeriodInSeconds(120)
        prometheusConfig.save()
        println("✓ Prometheus metrics enabled")
    }
} catch (Exception e) {
    println("Warning: Could not configure Prometheus: ${e.message}")
}

// 9. Configure build timestamps
println("Configuring build timestamps...")
def timestamperConfig = instance.getDescriptor("hudson.plugins.timestamper.TimestamperConfig")
if (timestamperConfig != null) {
    timestamperConfig.setAllPipelines(true)
    timestamperConfig.save()
    println("✓ Build timestamps configured")
}

// 10. Save everything
instance.save()

println("=== Jenkins Auto-Configuration Complete ===")
println("Jenkins is ready to use!")
println("URL: http://localhost:8080")
println("Username: admin")
println("Password: admin123")