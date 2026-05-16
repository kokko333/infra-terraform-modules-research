$ErrorActionPreference = "Stop"

$BUCKET = "terraform-state-kokko-sample"
$REGION = "ap-northeast-1"

$deployed = 0
$total    = 0

Write-Host "=== Terraform State Check ===" -ForegroundColor Cyan
Write-Host "[S3] s3://$BUCKET"
Write-Host "------------------------------"

$s3Lines = aws s3 ls "s3://$BUCKET/" --recursive --region $REGION
$s3Keys  = $s3Lines |
    Where-Object { $_ -match '\.tfstate$' } |
    ForEach-Object { ($_ -split '\s+', 4)[3].Trim() }

if (-not $s3Keys) {
    Write-Host "  (state files not found)"
} else {
    foreach ($key in $s3Keys) {
        $json  = (aws s3 cp "s3://$BUCKET/$key" - --region $REGION) -join ""
        $state = $json | ConvertFrom-Json
        $count = if ($state.resources) { @($state.resources).Count } else { 0 }
        $total++

        if ($count -gt 0) {
            Write-Host "  [DEPLOYED] $key ($count resources)" -ForegroundColor Red
            $deployed++
        } else {
            Write-Host "  [empty]    $key" -ForegroundColor Green
        }
    }
}

Write-Host ""
if ($deployed -gt 0) {
    Write-Host "=== Result: $deployed/$total state file(s) have deployed resources ===" -ForegroundColor Red
    exit 1
} else {
    Write-Host "=== Result: all $total state file(s) are empty ===" -ForegroundColor Green
}
