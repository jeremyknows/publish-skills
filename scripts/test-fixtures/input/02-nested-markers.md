# Test: nested markers (sanitizer should reject this)

<!-- atlas-private:start -->
outer private content
<!-- atlas-private:start -->
inner private — this is nested and should cause an error
<!-- /atlas-private:end -->
<!-- /atlas-private:end -->
