$baseUrl = "https://libraguard-api.onrender.com/api"

$loginData = @{
    email = "camesa.erasga31@gmail.com"
    password = "user123456"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginData -ContentType "application/json"
$token = $loginResponse.token

$headers = @{
    Authorization = "Bearer $token"
}

Write-Host "--- Auth Me Data ---"
$profileResponse = Invoke-RestMethod -Uri "$baseUrl/auth/me" -Method Get -Headers $headers
$profileResponse | ConvertTo-Json -Depth 10

Write-Host "--- Books Endpoint with ids ---"
try {
    $booksResponse = Invoke-RestMethod -Uri "$baseUrl/books?ids=b58e1507-7607-433c-800e-89bd79ccd9ab" -Method Get -Headers $headers
    $booksResponse | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Books endpoint error: $_"
}
