$docxPath = "C:\Users\laksh\Desktop\movie-rec-main\Movie_Recommendation_System_Report.docx"
$pdfPath = "C:\Users\laksh\Desktop\movie-rec-main\Movie_Recommendation_System_Report.pdf"

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Open($docxPath)
    $doc.SaveAs([ref]$pdfPath, [ref]17) # 17 = wdFormatPDF
    $doc.Close()
    $word.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
    Write-Host "PDF generated successfully at $pdfPath" -ForegroundColor Green
} catch {
    Write-Host "Word COM conversion failed: $_" -ForegroundColor Red
}
