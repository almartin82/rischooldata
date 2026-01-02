# TODO

## pkgdown Build Issues

### Network Timeout Error (2026-01-01)

The pkgdown build fails with network timeout errors when trying to check CRAN/Bioconductor package links:

```
Error in `httr2::req_perform()`:
! Failed to perform HTTP request.
Caused by error in `curl::curl_fetch_memory()`:
! Timeout was reached [cloud.r-project.org]:
Connection timed out after 10001 milliseconds
```

**Cause:** pkgdown's `cran_link()` function attempts to verify if the package exists on CRAN, which requires network access to cloud.r-project.org and www.bioconductor.org.

**Workarounds attempted:**
- `options(pkgdown.internet = FALSE)` - did not prevent network calls
- `Sys.setenv(PKGDOWN_INTERNET = 'false')` - did not prevent network calls

**Possible solutions:**
1. Run pkgdown build on a machine with reliable network access
2. Set up CI/CD (GitHub Actions) which typically has stable network connectivity
3. Check firewall/proxy settings if running locally
4. Wait for network connectivity to be restored and retry

**Note:** The vignette code itself appears correct - it uses 2011-2026 year ranges which should be valid for the RIDE data source. The issue is purely a network connectivity problem during the pkgdown build process.
